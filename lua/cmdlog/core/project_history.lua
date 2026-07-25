---@module 'cmdlog.core.project_history'
--- Maintains a persistent, per-Git-root command log so `:Cmdlog project`
--- can show only commands run while working inside the current project.
--- Neovim's built-in `:history` has no notion of cwd/project, so this
--- module records new entries going forward via core/tracker.lua; it
--- cannot retroactively attribute history from before tracking started.
local config = require("cmdlog.config")
local store = require("cmdlog.core.store")

local M = {}

---@type table<string, string[]>|nil
local cache = nil

--- Resolve the current Git root, or nil if not inside a repository.
---@return string|nil
function M.get_git_root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not out or not out[1] or out[1] == "" then
    return nil
  end
  return (out[1]:gsub("\\", "/"))
end

---@return table<string, string[]>
local function load()
  if cache then
    return cache
  end
  cache = store.load_json(config.options.project_history_path, {})
  if type(cache) ~= "table" then
    cache = {}
  end
  return cache
end

--- Record a command against the given (or current) Git root.
---@param cmd string
---@param root string|nil
function M.record(cmd, root)
  if not cmd or cmd == "" then
    return
  end
  root = root or M.get_git_root()
  if not root then
    return
  end

  local data = load()
  data[root] = data[root] or {}
  table.insert(data[root], cmd)

  cache = data
  store.save_json(config.options.project_history_path, data)
end

--- Return the recorded command list for the current Git root (oldest to
--- newest), or an empty list when not inside a Git repository.
---@return string[]
function M.get_project_history()
  local root = M.get_git_root()
  if not root then
    return {}
  end
  local data = load()
  return data[root] or {}
end

return M
