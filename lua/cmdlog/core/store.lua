---@module 'cmdlog.core.store'
--- Small shared JSON persistence helper for cmdlog's tracking modules
--- (project history, stats, error log). Mirrors the defensive
--- directory-creation strategy used by core/favorites.lua so every
--- on-disk store behaves the same way, especially on Windows.
local Path = require("plenary.path")
local uv = vim.loop

local M = {}

---@param p string
---@return boolean
local function is_dir(p)
  if not p or p == "" then
    return false
  end
  local ok, res = pcall(vim.fn.isdirectory, p)
  if ok then
    return res == 1
  end
  ---@diagnostic disable-next-line lib.uv
  local stat = uv.fs_stat(p)
  return stat and stat.type == "directory"
end

---@param file_path string
---@return boolean, string|nil
local function ensure_parent_exists(file_path)
  if not file_path or file_path == "" then
    return false, "empty file_path"
  end

  local expanded = vim.fn.expand(file_path)
  local parent = vim.fn.fnamemodify(expanded, ":h")
  if parent == "" or parent == "." or is_dir(parent) then
    return true, nil
  end

  local ok, res = pcall(vim.fn.mkdir, parent, "p")
  if ok and res == 1 then
    return true, nil
  end

  local ok2, res2 = pcall(function()
    Path:new(expanded):parent():mkdir({ parents = true })
  end)
  if ok2 then
    return true, nil
  end

  return false, tostring(res) .. " | " .. tostring(res2)
end

--- Load a JSON file from disk.
---@param path string
---@param default any Value returned when the file is missing/empty/invalid
---@return any
function M.load_json(path, default)
  local p = Path:new(path)
  if not p:exists() then
    return default
  end

  local ok, content = pcall(function()
    return p:read()
  end)
  if not ok or not content or content == "" then
    return default
  end

  local ok_json, decoded = pcall(vim.fn.json_decode, content)
  if not ok_json or decoded == nil then
    return default
  end

  return decoded
end

--- Save a value as JSON to disk, creating parent directories as needed.
---@param path string
---@param data any
---@return boolean success
function M.save_json(path, data)
  local ok_ensure, err = ensure_parent_exists(path)
  if not ok_ensure then
    vim.notify(
      ("[cmdlog.store] Failed to ensure parent directory for '%s': %s"):format(tostring(path), tostring(err)),
      vim.log.levels.ERROR
    )
  end

  local encoded = vim.fn.json_encode(data)
  local expanded = vim.fn.expand(path)

  local ok_write, write_err = pcall(function()
    Path:new(expanded):write(encoded, "w")
  end)
  if ok_write then
    return true
  end

  local f_ok, f_err = pcall(function()
    local fh, ferr = io.open(expanded, "wb")
    if not fh then
      error(tostring(ferr))
    end
    fh:write(encoded)
    fh:close()
  end)

  if not f_ok then
    vim.notify(
      ("[cmdlog.store] Failed to write '%s': %s (fallback: %s)"):format(
        tostring(path),
        tostring(write_err),
        tostring(f_err)
      ),
      vim.log.levels.ERROR
    )
    return false
  end

  return true
end

return M
