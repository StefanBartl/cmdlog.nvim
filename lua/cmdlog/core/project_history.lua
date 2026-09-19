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
-- caching, every single ':' command would block on a filesystem walk (and, in
-- the subprocess days, a `git rev-parse` spawn). TTL-cached per cwd: short
-- enough that switching projects is picked up quickly, long enough to absorb
-- bursts of commands typed in the same session.
local git_root_cache =
  require("lib.nvim.cache.memory").namespace("cmdlog.project_history.git_root", {
    ttl = 3,
  })

--- Resolve the current Git root, or nil if not inside a repository.
--- Cached per cwd for a few seconds (see module comment above) to keep the
--- upward `.git` walk off every ':' command.
---@return string|nil
function M.get_git_root()
  local cwd = vim.fn.getcwd()

  local cached = git_root_cache.get(cwd)
  if cached ~= nil then return cached ~= "" and cached or nil end

  -- Pure filesystem walk instead of spawning `git rev-parse --show-toplevel`.
  -- The subprocess blocked the UI thread on every cache miss (on Windows a
  -- process spawn costs 15-40ms); vim.fs.find only issues stat() calls.
  -- `.git` is matched as both directory and file so worktrees and submodules
  -- (where `.git` is a gitfile) resolve correctly.
  local found = vim.fs.find(".git", { path = cwd, upward = true, limit = 1 })
  local root = nil
  if found and found[1] then
    local dir = vim.fs.dirname(found[1])
    if dir and dir ~= "" then root = (dir:gsub("\\", "/")) end
  end

  -- Cache "" for "not a Git repo" -- ns.get() can't otherwise distinguish
  -- "no root" from "not cached yet", since both would be nil.
  git_root_cache.set(cwd, root or "")
  return root
end

-- Generous headroom over any real project/command-history size; a corrupt
-- or hand-edited project_history.json with more than this is rejected
-- outright, not silently truncated.
local MAX_ROOTS = 20000
local MAX_COMMANDS_PER_ROOT = 20000

---@internal
--- A persisted project_history.json is untrusted input (SEC-33): decoding
--- as valid JSON only means the file was well-formed, not that it has the
--- shape this module wrote -- `data[root]` reaches `core.utils.process_list`
--- downstream, which expects a list of strings. Rejects the whole load on
--- the first bad entry rather than trying to salvage individual ones.
---
--- Passed to `store.load_json` as its `validate` (ERR-11): a shape-invalid
--- file is well-formed JSON, so `json_decode` alone never flags it, and
--- without this hooked into the same backup path as a decode failure,
--- `M.record`'s next load-modify-save would silently overwrite it with a
--- near-empty file, no backup, no trace it was ever anything else.
---@param data any
---@return boolean ok
local function is_valid(data)
  if type(data) ~= "table" then return false end
  local roots = 0
  for root, cmds in pairs(data) do
    roots = roots + 1
    if roots > MAX_ROOTS then return false end
    if type(root) ~= "string" then return false end
    if type(cmds) ~= "table" then return false end
    if #cmds > MAX_COMMANDS_PER_ROOT then return false end
    for _, cmd in ipairs(cmds) do
      if type(cmd) ~= "string" then return false end
    end
  end
  return true
end

---@internal
---@return table<string, string[]>
local function load()
  if cache then return cache end
  cache = store.load_json(config.options.project_history_path, {}, is_valid)
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
