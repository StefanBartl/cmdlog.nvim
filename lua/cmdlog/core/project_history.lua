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

-- core.tracker calls M.record() on every ':' command (CmdlineLeave), and
-- M.record() resolves the Git root when none is passed in -- so without
-- caching, every single ':' command would block on a synchronous `git
-- rev-parse` subprocess spawn. TTL-cached per cwd (see PERFORMANCE.md ->
-- Cache-Regeln); short enough that switching projects is picked up quickly,
-- long enough to absorb bursts of commands typed in the same session.
local git_root_cache =
  require("lib.nvim.cache.memory").namespace("cmdlog.project_history.git_root", {
    ttl = 3,
  })

--- Resolve the current Git root, or nil if not inside a repository.
--- Cached per cwd for a few seconds (see module comment above) to avoid
--- spawning `git rev-parse` on every ':' command.
---@return string|nil
function M.get_git_root()
  local cwd = vim.fn.getcwd()

  local cached = git_root_cache.get(cwd)
  if cached ~= nil then return cached ~= "" and cached or nil end

  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  local root = nil
  if vim.v.shell_error == 0 and out and out[1] and out[1] ~= "" then
    root = (out[1]:gsub("\\", "/"))
  end

  -- Cache "" for "not a Git repo" -- ns.get() can't otherwise distinguish
  -- "no root" from "not cached yet", since both would be nil.
  git_root_cache.set(cwd, root or "")
  return root
end

---@internal
---@return table<string, string[]>
local function load()
  if cache then return cache end
  cache = store.load_json(config.options.project_history_path, {})
  if type(cache) ~= "table" then cache = {} end
  return cache
end

--- Record a command against the given (or current) Git root.
---@param cmd string
---@param root string|nil
function M.record(cmd, root)
  if not cmd or cmd == "" then return end
  root = root or M.get_git_root()
  if not root then return end

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
  if not root then return {} end
  local data = load()
  return data[root] or {}
end

return M
