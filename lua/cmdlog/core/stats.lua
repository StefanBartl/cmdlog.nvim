---@module 'cmdlog.core.stats'
--- Tracks usage frequency and last-used timestamp per command, fed by
--- core/tracker.lua on every ':' command. Backs `:Cmdlog stats`.
local config = require("cmdlog.config")
local store = require("cmdlog.core.store")

local M = {}

---@type table<string, { count: integer, last_used: integer }>|nil
local cache = nil

---@internal
---@return table<string, { count: integer, last_used: integer }>
local function load()
  if cache then return cache end
  cache = store.load_json(config.options.stats_path, {})
  if type(cache) ~= "table" then cache = {} end
  return cache
end

--- Record one execution of `cmd`, bumping its count and last_used timestamp.
---@param cmd string
function M.record(cmd)
  if not cmd or cmd == "" then return end

  local data = load()
  local entry = data[cmd] or { count = 0, last_used = 0 }
  entry.count = entry.count + 1
  entry.last_used = os.time()
  data[cmd] = entry

  cache = data
  store.save_json(config.options.stats_path, data)
end

--- Return all recorded stats.
---@return table<string, { count: integer, last_used: integer }>
function M.all()
  return load()
end

--- Return commands sorted by usage count (descending, ties broken by
--- most-recently-used first).
---@return string[]
function M.by_frequency()
  local data = load()
  local cmds = vim.tbl_keys(data)
  table.sort(cmds, function(a, b)
    if data[a].count ~= data[b].count then return data[a].count > data[b].count end
    return data[a].last_used > data[b].last_used
  end)
  return cmds
end

--- Human-readable "used N times, last used <date>" label for a command.
---@param cmd string
---@return string|nil
function M.describe(cmd)
  local entry = load()[cmd]
  if not entry then return nil end
  return ("used %dx, last %s"):format(entry.count, os.date("%Y-%m-%d %H:%M", entry.last_used))
end

return M
