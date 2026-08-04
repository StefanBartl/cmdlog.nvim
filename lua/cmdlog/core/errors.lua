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

---@internal
---@return table<string, string>
local function load()
  if cache then
    return cache
  end
  cache = store.load_json(config.options.errors_path, {})
  if type(cache) ~= "table" then
    cache = {}
  end
  return cache
end

--- Record that `cmd` failed with `errmsg`.
---@param cmd string
---@param errmsg string
function M.record(cmd, errmsg)
  if not cmd or cmd == "" then
    return
  end

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
---@param cmd string
---@return string|nil
function M.get_error(cmd)
  return load()[cmd]
end

return M
