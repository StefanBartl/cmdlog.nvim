---@module 'cmdlog.core.extra_files'
--- Reads user-configured extra command files (`extra_files` option) as
--- additional read-only history sources -- plain newline-separated command
--- lists, no favorites/tags/delete support, just folded into the relevant
--- pickers alongside Neovim/shell history.
local config = require("cmdlog.config")
local expand_path = require("lib.nvim.cross.fs.expand_path")

local M = {}

--- Reads non-empty lines from `path`. Missing/unreadable files yield an
--- empty list rather than an error -- this mirrors core/shell.lua's own
--- best-effort `vim.fn.readfile` usage.
---@internal
---@param path string
---@return string[]
local function read_lines(path)
  -- expand_path, not vim.fn.expand (SEC-34): `path` comes from the
  -- user-configured `extra_files.history`/`extra_files.all` list -- the
  -- same hazard class already fixed in core/favorites.lua and
  -- core/store.lua: vim.fn.expand() runs backtick spans through &shell and
  -- treats a leading '#'/'%' as a Vim cmdline special.
  local expanded = expand_path(path)
  local ok, lines = pcall(vim.fn.readfile, expanded)
  if not ok or not lines then return {} end

  local out = {}
  for _, line in ipairs(lines) do
    if line ~= "" then table.insert(out, line) end
  end
  return out
end

---@internal
---@param kind '"history"'|'"all"'
---@return string[]
local function get(kind)
  local files = config.options.extra_files and config.options.extra_files[kind]
  if type(files) ~= "table" then return {} end

  local out = {}
  for _, path in ipairs(files) do
    vim.list_extend(out, read_lines(path))
  end
  return out
end

--- Entries from every file configured under `extra_files.history` -- folded
--- into the Neovim-history-based pickers and the combined pickers.
---@return string[]
function M.get_history()
  return get("history")
end

--- Entries from every file configured under `extra_files.all` -- folded
--- only into the combined `:Cmdlog`/`:Cmdlog full` pickers.
---@return string[]
function M.get_all()
  return get("all")
end

return M
