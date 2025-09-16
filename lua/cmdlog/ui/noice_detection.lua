---@module 'cmdlog.util.enabled'
--- Detect whether "cmdlog messages" are enabled in the current Neovim instance.
--- Adds a tiny memoization to avoid repeated module loads in hot paths.

---@class CmdlogEnabledCache
---@field val boolean|nil
---@field src string|nil
---@field ts  integer|nil

local _cache ---@type CmdlogEnabledCache|nil

---@class CmdlogEnabledOpts
---@field soft boolean|nil  -- if true, do not require modules; only use package.loaded + globals
---@field ttl  integer|nil  -- optional cache TTL in seconds (default: 2)

---@nodiscard
---@param opts CmdlogEnabledOpts|nil
---@return boolean enabled, string source
local function is_cmdlog_messages_enabled(opts)
  opts = opts or {}
  local soft = opts.soft and true or false
  local ttl  = tonumber(opts.ttl or 2)

  -- tiny time-based cache
  if _cache and _cache.ts and (os.time() - _cache.ts) <= ttl then
    return _cache.val == true, _cache.src or "unknown"
  end

  local function load_mod(mod)
    if soft then
      local m = package.loaded[mod]
      return (m ~= nil), m
    else
      local ok, m = pcall(require, mod)
      return ok and type(m) == "table", ok and m or nil
    end
  end

  -- 1) Public API
  do
    local ok, api = load_mod("cmdlog.api")
    if ok and type(api.is_messages_enabled) == "function" then
      local ok2, val = pcall(api.is_messages_enabled)
      if ok2 and type(val) == "boolean" then
        _cache = { val = val, src = "api", ts = os.time() }
        return val, "api"
      end
    end
  end

  -- 2) Config modules
  do
    local candidates = { "cmdlog.config", "cmdlog", "cmdlog.core.config" } ---@type string[]
    for _, name in ipairs(candidates) do
      local ok, cfg = load_mod(name)
      if ok then
        local function pick(v)
          if type(v) == "table" then
            if type(v.enabled) == "boolean" then return v.enabled end
            if type(v.enable)  == "boolean" then return v.enable  end
          end
          return nil
        end
        local val = nil
        if type(cfg.messages) == "table" then val = pick(cfg.messages) end
        if val == nil and type(cfg.cfg) == "table" and type(cfg.cfg.messages) == "table" then
          val = pick(cfg.cfg.messages)
        end
        if type(val) == "boolean" then
          _cache = { val = val, src = "config", ts = os.time() }
          return val, "config"
        end
      end
    end
  end

  -- 3) Globals
  do
    local gkeys = {
      "cmdlog_messages_enabled",
      "cmdlog_enable_messages",
      "nvim_cmdlog_messages",
      "nvim_cmdlog_enable_messages",
    } ---@type string[]
    for _, k in ipairs(gkeys) do
      local v = rawget(vim.g, k)
      if type(v) == "boolean" then
        _cache = { val = v, src = "global", ts = os.time() }
        return v, "global"
      elseif v == 1 or v == 0 then
        local val = (v == 1)
        _cache = { val = val, src = "global", ts = os.time() }
        return val, "global"
      end
    end
  end

  -- 4) Heuristic based on user commands
  do
    local function cmd_exists(name) return vim.fn.exists(":" .. name) == 2 end
    if cmd_exists("CmdlogMessagesOpen") or cmd_exists("CmdlogMessagesToggle") then
      _cache = { val = true, src = "command-exists", ts = os.time() }
      return true, "command-exists"
    end
  end

  _cache = { val = false, src = "unknown", ts = os.time() }
  return false, "unknown"
end

return { is_cmdlog_messages_enabled = is_cmdlog_messages_enabled }
