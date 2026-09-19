---@module 'cmdlog.core.store'
--- Small shared JSON persistence helper for cmdlog's tracking modules
--- (project history, stats, error log).
---
--- All filesystem I/O goes through lib.nvim (fs.is_readable_file, fs.read,
--- fs.write.to_file), so this module carries no plenary.nvim dependency.
--- `fs.write.to_file` also creates missing parent directories, covering the
--- Windows/Unix mkdir edge cases itself.

local is_readable_file = require("lib.nvim.fs.is_readable_file")
local read_file = require("lib.nvim.fs.read")
local write_to_file = require("lib.nvim.fs.write.to_file")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.store]")

local M = {}

--- Load a JSON file from disk.
---
--- `err` distinguishes "nothing to load" (file missing or empty -- `default`
--- is the right, unsurprising answer) from "load failed" (file exists but
--- isn't valid JSON). Every consumer of this module is a load-modify-save
--- cycle: it calls this, mutates the result, and hands the WHOLE table to
--- `save_json`, which rewrites the whole file -- collapsing both cases to
--- the same empty `default` means the very next write silently replaces a
--- corrupt file with a near-empty one. On a decode failure the original
--- bytes are backed up once, to `<path>.corrupt`, so that loss stays
--- recoverable even though the caller still gets `default` back this
--- session.
---@param path string
---@param default any Value returned when the file is missing/empty/invalid
---@return any data
---@return string|nil err `nil` when the file is missing or empty; set when
---  it exists but could not be decoded.
function M.load_json(path, default)
  local target = vim.fn.expand(path)

  if not is_readable_file(target) then return default, nil end

  local content = read_file(target)
  if not content or content == "" then return default, nil end

  local ok_json, decoded = pcall(vim.fn.json_decode, content)
  if not ok_json or decoded == nil then
    local backup_path = target .. ".corrupt"
    if not is_readable_file(backup_path) then write_to_file(backup_path, content) end
    notify.error(("'%s' is not valid JSON; original kept at '%s'"):format(target, backup_path))
    return default, "invalid JSON: original kept at " .. backup_path
  end

  return decoded, nil
end

--- Save a value as JSON to disk, creating parent directories as needed.
---@param path string
---@param data any
---@return boolean success
function M.save_json(path, data)
  local encoded = vim.fn.json_encode(data)
  local target = vim.fn.expand(path)

  local ok, err = write_to_file(target, encoded)
  if not ok then
    notify.error(("Failed to write '%s': %s"):format(tostring(path), tostring(err)))
    return false
  end

  return true
end

return M
