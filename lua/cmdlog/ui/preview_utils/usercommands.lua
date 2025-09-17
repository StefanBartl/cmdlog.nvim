---@module 'cmdlog.ui.preview_utils.usercommands'

-- #####################################################################
-- Helpers for user-defined Ex commands
-- #####################################################################

local M = {}

local excmds = require("cmdlog.ui.preview_utils.excommands_utils")

---@class UserCmdIndex
---@field ts integer
---@field map table<string, any>   -- UPPER(name) -> spec (from nvim_get_commands)

local _UCACHE_GLOBAL ---@type UserCmdIndex|nil
local _UCACHE_BUFFER ---@type UserCmdIndex|nil

---@nodiscard
---@param ttl integer|nil
---@return table<string, any>
-- Index global user-commands (builtin=false) with a tiny TTL cache.
local function _usercmd_index_global(ttl)
  ttl = tonumber(ttl or 2)
  local now = os.time()
  if _UCACHE_GLOBAL and (now - _UCACHE_GLOBAL.ts <= ttl) and _UCACHE_GLOBAL.map then
    return _UCACHE_GLOBAL.map
  end
  local ok, cmds = pcall(vim.api.nvim_get_commands, { builtin = false })
  local idx = {}
  if ok and type(cmds) == "table" then
    for name, spec in pairs(cmds) do
      idx[string.upper(tostring(name))] = spec
    end
  end
  _UCACHE_GLOBAL = { ts = now, map = idx }
  return idx
end

---@nodiscard
---@param ttl integer|nil
---@return table<string, any>
-- Index buffer-local user-commands (buf=0) with a tiny TTL cache.
local function _usercmd_index_buffer(ttl)
  ttl = tonumber(ttl or 2)
  local now = os.time()
  if _UCACHE_BUFFER and (now - _UCACHE_BUFFER.ts <= ttl) and _UCACHE_BUFFER.map then
    return _UCACHE_BUFFER.map
  end
  local ok, cmds = pcall(vim.api.nvim_get_commands, { builtin = false, buf = 0 })
  local idx = {}
  if ok and type(cmds) == "table" then
    for name, spec in pairs(cmds) do
      idx[string.upper(tostring(name))] = spec
    end
  end
  _UCACHE_BUFFER = { ts = now, map = idx }
  return idx
end

---@nodiscard
---@param n any
---@return string
-- Render nargs into a human-readable phrase.
local function _fmt_nargs(n)
  local m = tostring(n or "")
  if m == "0" then return "no args" end
  if m == "1" then return "exactly 1 arg" end
  if m == "?" then return "0 or 1 arg" end
  if m == "*" then return "0+ args" end
  if m == "+" then return "1+ args" end
  return tostring(n)
end

---@nodiscard
---@param spec table
---@return string
-- Format a compact description block for a user command.
local function _format_usercmd_spec(spec)
  local lines = { [8] = "" } ---@type string[]
  local i = 0

  local name = tostring(spec.name or "?")
  local has_bang = spec.bang and true or false

  i = i + 1
  lines[i] = string.format(("--- :%s%s —--"),
    name, has_bang and " [!]" or "")

  -- Attributes
  local attrs = { [8] = "" } ---@type string[]
  local j = 0
  if spec.nargs ~= nil then j = j + 1; attrs[j] = "nargs: " .. _fmt_nargs(spec.nargs) end
  if spec.range then     j = j + 1; attrs[j] = "range: allowed" end
  if tonumber(spec.count or 0) > 0 then j = j + 1; attrs[j] = "count: " .. tostring(spec.count) end
  if spec.register then  j = j + 1; attrs[j] = "register: yes" end
  if spec.bar then       j = j + 1; attrs[j] = "bar: yes" end
  if spec.addr and spec.addr ~= "" then j = j + 1; attrs[j] = "addr: " .. tostring(spec.addr) end
  if spec.buffer then    j = j + 1; attrs[j] = "scope: buffer-local" end
  if j > 0 then i = i + 1; lines[i] = table.concat(attrs, " · ", 1, j) end

  -- Definition / callback hint
  local def = tostring(spec.definition or "")
  if def ~= "" then
    i = i + 1; lines[i] = "description: " .. def
  elseif spec.lua then
    i = i + 1; lines[i] = "callback: <Lua function>"
  end

  for k = i + 1, #lines do lines[k] = nil end
  return table.concat(lines, "\n")
end

---@nodiscard
---@param cmd string
---@return string|nil
-- Try to preview a user-defined command:
--   * Skips common Ex modifiers (silent, vertical, keepjumps, …)
--   * Case-insensitive match against global and buffer-local user commands
--   * Returns a formatted info block or nil if not a user command
function M.try_preview(cmd)
  -- Parse first real command token after modifiers (re-use your helper if present)
  local name = (excmds.ex_head_after_mods and excmds.ex_head_after_mods(cmd) or excmds.head_token(cmd)) ---@type string
  if name == "" then return nil end
  local key = string.upper(name)

  -- Check buffer-local first (more specific), then global
  local buf_idx = _usercmd_index_buffer(10)
  local spec = buf_idx[key]
  if not spec then
    local glob_idx = _usercmd_index_global(10)
    spec = glob_idx[key]
  end
  if not spec then return nil end
  return _format_usercmd_spec(spec)
end

return M
