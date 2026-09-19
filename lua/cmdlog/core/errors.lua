---@module 'cmdlog.core.errors'
--- Tracks commands that produced an error the last time they ran, so
--- pickers can visually flag entries with a known-bad track record.
--- Detection relies on `vim.v.errmsg`, which Neovim only updates *after*
--- the command-line command actually executes -- i.e. after CmdlineLeave
--- has already fired -- so core/tracker.lua defers the check with
--- vim.schedule() and compares against the errmsg seen before execution.
local config = require("cmdlog.config")
local store = require("cmdlog.core.store")

local M = {}

---@type table<string, string>|nil
local cache = nil

-- Generous headroom over any real command-history size; a corrupt or
-- hand-edited errors.json with more entries than this is rejected outright,
-- not silently truncated.
local MAX_ENTRIES = 20000

---@internal
--- A persisted errors.json is untrusted input (mirrors SEC-33 in
--- stats/tags/project_history): decoding as valid JSON only means the file
--- was well-formed, not that it has the `table<string, string>` shape this
--- module wrote -- e.g. a JSON array or a bare number also decode cleanly.
---
--- Passed to `store.load_json` as its `validate` (ERR-11): without this
--- hooked into the same backup path as a decode failure, a wrong-shape file
--- passed the old plain `type(cache) ~= "table"` check whenever the decoded
--- value happened to be a table of the wrong shape (e.g. a JSON array), and
--- `M.record`'s next load-modify-save would silently overwrite it with a
--- near-empty file, no backup, no trace it was ever anything else.
---@param data any
---@return boolean ok
local function is_valid(data)
  if type(data) ~= "table" then return false end
  local n = 0
  for cmd, errmsg in pairs(data) do
    n = n + 1
    if n > MAX_ENTRIES then return false end
    if type(cmd) ~= "string" then return false end
    if type(errmsg) ~= "string" then return false end
  end
  return true
end

---@internal
---@return table<string, string>
local function load()
  if cache then return cache end
  cache = store.load_json(config.options.errors_path, {}, is_valid)
  return cache
end

--- Record that `cmd` failed with `errmsg`.
---@param cmd string
---@param errmsg string
function M.record(cmd, errmsg)
  if not cmd or cmd == "" then return end

  local data = load()
  data[cmd] = errmsg
  cache = data
  store.save_json(config.options.errors_path, data)
end

--- Whether `cmd` is known to have failed previously.
---@param cmd string
---@return boolean
function M.is_known_bad(cmd)
  return load()[cmd] ~= nil
end

--- Last recorded error message for `cmd`, if any.
--- CDX: no callers in the repo and not a documented API -- only `is_known_bad`
--- is consumed (by ui/picker_utils). Vestigial accessor or unfinished feature.
---@param cmd string
---@return string|nil
function M.get_error(cmd)
  return load()[cmd]
end

return M
