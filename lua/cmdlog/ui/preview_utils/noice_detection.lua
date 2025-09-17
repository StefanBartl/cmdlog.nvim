---@module 'cmdlog.ui.preview_utils.noice_detection'
--- Detect whether Noice is active and `messages.enabled` is true.
--- This module is defensive, side-effect free (no UI), and suitable for hot paths.
--- It uses a small time-based memoization and multiple detection strategies:
--- 1) Read Noice's public-ish config table (if available)      → "noice.config"
--- 2) Look for plausible global flags                          → "global"
--- 3) Heuristics (user commands/modules loaded)                → "heuristic"
--- 4) Fallback                                                 → "unknown"
---
--- Returned `source` helps diagnosing which branch matched.
--- Note: Noice internals may change; this detector prefers stable hints first.

local M = {}

-- Internal, module-local cache (not global)
---@type NoiceDetectCache|nil
local _cache = nil

--- Internal helper: safe module access. Honors `soft` mode.
---@param mod string
---@param soft boolean
---@return boolean ok, table? m
local function safe_load(mod, soft)
  if soft then
    local m = package.loaded[mod]
    return type(m) == "table", m
  end
  local ok, m = pcall(require, mod)
  return ok and type(m) == "table", ok and m or nil
end

--- Internal helper: nested key read with guards, e.g. getopt(t, "messages", "enabled")
---@param t table|nil
---@param k1 string
---@param k2 string|nil
---@return any
local function getopt(t, k1, k2)
  if type(t) ~= "table" then return nil end
  local v = t[k1]
  if k2 ~= nil and type(v) == "table" then
    return v[k2]
  end
  return v
end

--- Returns whether Noice is active and `messages.enabled` is true, plus the detected source.
--- No UI side-effects; safe to call frequently (uses a tiny TTL cache).
---@nodiscard
---@param opts NoiceDetectOpts|nil
---@return boolean enabled, string source
function M.is_noice_messages_enabled(opts)
  opts = opts or {}
  local soft = opts.soft and true or false
  local ttl  = tonumber(opts.ttl or 2) or 2

  -- Tiny TTL cache for hot paths
  local now = os.time()
  if _cache and _cache.ts and (now - _cache.ts) <= ttl then
    return _cache.val == true, _cache.src or "unknown"
  end

  -- 1) Prefer stable config surface: require("noice.config"), read `.options` or `.defaults`
  do
    local ok, cfg = safe_load("noice.config", soft)
    if ok then
      -- Known shapes seen in the wild:
      --   cfg.options.messages.enabled
      --   cfg.defaults.messages.enabled
      local opt_enabled = getopt(getopt(cfg, "options"), "messages", "enabled")
      local def_enabled = getopt(getopt(cfg, "defaults"), "messages", "enabled")
      local val = opt_enabled
      if type(val) ~= "boolean" then val = def_enabled end
      if type(val) == "boolean" then
        _cache = { val = val, src = "noice.config", ts = now }
        return val, "noice.config"
      end
    end
  end

  -- 2) Globals (project-agnostic hints users might set)
  do
    -- Accept common boolean patterns; 0/1 normalized to boolean true/false.
    local gkeys = { [4] = "" }
    gkeys[1] = "noice_messages_enabled"
    gkeys[2] = "noice_enable_messages"
    gkeys[3] = "noice_cmd_messages"

    for i = 1, 4 do
      local k = gkeys[i]
      if type(k) == "string" and k ~= "" then
        local v = rawget(vim.g, k)
        if type(v) == "boolean" then
          _cache = { val = v, src = "global", ts = now }
          return v, "global"
        elseif v == 1 or v == 0 then
          local val = (v == 1)
          _cache = { val = val, src = "global", ts = now }
          return val, "global"
        end
      end
    end
  end

  -- 3) Heuristics:
  --    a) Noice user command exists → Noice loaded; still need to infer `messages.enabled`.
  --    b) Some Noice core modules loaded (package.loaded) → likely active.
  --    c) If we only have this heuristic, assume "enabled" conservatively false unless hints say otherwise.
  do
    local function cmd_exists(name)
      -- exists(":Cmd") returns 2 if user-command, 1 if Ex command; we check >=1
      local ok, v = pcall(vim.fn.exists, ":" .. name)
      return ok and tonumber(v) and tonumber(v) >= 1
    end

    local noice_cmd = cmd_exists("Noice")
    local loaded_core =
      (package.loaded["noice"] ~= nil)
      or (package.loaded["noice.api"] ~= nil)
      or (package.loaded["noice.message"] ~= nil)
      or (package.loaded["noice.view"] ~= nil)
      or (package.loaded["noice.router"] ~= nil)

    if noice_cmd or loaded_core then
      -- Soft probe for messages.enabled without hard require in soft-mode:
      -- try to peek a loaded config table if present in package.loaded
      local cfg = package.loaded["noice.config"]
      local val = nil
      if type(cfg) == "table" then
        local opt_enabled = getopt(getopt(cfg, "options"), "messages", "enabled")
        local def_enabled = getopt(getopt(cfg, "defaults"), "messages", "enabled")
        val = type(opt_enabled) == "boolean" and opt_enabled
              or (type(def_enabled) == "boolean" and def_enabled or nil)
      end

      if type(val) == "boolean" then
        _cache = { val = val, src = "heuristic-config", ts = now }
        return val, "heuristic-config"
      else
        -- Heuristic presence without explicit flag → default to false (defensive)
        _cache = { val = false, src = "heuristic", ts = now }
        return false, "heuristic"
      end
    end
  end

  -- 4) Fallback: Nothing indicates that Noice would override :messages
  _cache = { val = false, src = "unknown", ts = now }
  return false, "unknown"
end

return M
