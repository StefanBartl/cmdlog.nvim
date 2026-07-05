---@module 'cmdlog.core.notes'
--- Persistent per-command notes storage and buffer management.

local config = require("cmdlog.config")
local is_dir = require("lib.nvim.fs.is_dir")

local api = vim.api
local fn  = vim.fn

local M = {}

---@param path string
local function ensure_dir(path)
  if path == "" then return end
  if not is_dir(path) then
    fn.mkdir(path, "p")
  end
end

---@param s string
---@return string
local function normalize_cmd(s)
  s = tostring(s or "")
  s = s:match("^%s*(.-)%s*$") or s
  if s:sub(1, 1) == ":" then
    s = s:sub(2)
  end
  s = s:gsub("%s+", " ")
  return s
end

---@param cmd string
---@return string
local function note_key(cmd)
  local n = normalize_cmd(cmd)
  n = n:gsub("[^%w%-_.]", "_")
  return n
end

---@param cmd string
---@return string
local function note_path(cmd)
  local dir = config.options.notes.dir
  ensure_dir(dir)

  local ext = (config.options.notes.format == "markdown") and ".md" or ".txt"
  return dir .. "/" .. note_key(cmd) .. ext
end

---@param path string
---@return integer
local function open_note_buffer(path)
  for _, bufnr in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_loaded(bufnr) and api.nvim_buf_get_name(bufnr) == path then
      return bufnr
    end
  end

  local bufnr = api.nvim_create_buf(true, false)
  api.nvim_buf_set_name(bufnr, path)

  if fn.filereadable(path) == 1 then
    api.nvim_buf_call(bufnr, function()
      vim.cmd("silent read " .. fn.fnameescape(path))
      vim.cmd("silent 1delete")
    end)
  end

  api.nvim_set_option_value("buftype", "", { buf = bufnr })
  api.nvim_set_option_value("swapfile", false, { buf = bufnr })
  api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })

  api.nvim_set_option_value("filetype", config.options.notes.format == "markdown" and "markdown" or "text", { buf = bufnr })

  return bufnr
end

---@param bufnr integer
---@param path string
local function attach_autosave(bufnr, path)
  if not config.options.notes.autosave then return end

  api.nvim_create_autocmd({ "BufWritePost", "TextChanged", "TextChangedI" }, {
    buffer = bufnr,
    callback = function()
      if not api.nvim_buf_is_valid(bufnr) then return end
      local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
      fn.writefile(lines, path)
    end,
  })
end

---@param cmd string
---@return integer|nil
function M.open(cmd)
  if not config.options.notes.enabled then
    return nil
  end

  local path = note_path(cmd)
  local bufnr = open_note_buffer(path)
  attach_autosave(bufnr, path)

  -- Show the buffer in the current window (temporary test behavior)
  vim.api.nvim_set_current_buf(bufnr)

  return bufnr
end


return M
