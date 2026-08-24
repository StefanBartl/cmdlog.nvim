---@module 'cmdlog.core.risky'
--- Detects commands that are prone to causing damage or data loss, so
--- pickers can highlight them (see cmdlog.ui.picker_utils).

local M = {}

--- Every configured pattern that matches `cmd`.
---
--- `is_risky` only answers yes/no, which is all a picker needs to colour a
--- line but not enough to tune the list: a pattern that never fires and a
--- pattern that fires on everything look identical from the outside. This
--- returns the actual matches, so `:Cmdlog risky test <cmd>` can show which
--- one is responsible.
---
--- Ignores `highlight_risky`: that switch is about *displaying* the result,
--- and someone testing their patterns wants to see them evaluated either way.
---@param cmd string
---@return string[] patterns  # matching patterns, in configured order
function M.matching(cmd)
  local matches = {}
  if type(cmd) ~= "string" or cmd == "" then return matches end

  local patterns = require("cmdlog.config").options.risky_patterns
  if type(patterns) ~= "table" then return matches end

  for _, pattern in ipairs(patterns) do
    -- A user-supplied pattern can be malformed ("unfinished capture", a bad
    -- character class); a bad entry should exclude itself, not blow up the
    -- picker that is merely colouring a line.
    local ok, found = pcall(string.find, cmd, pattern)
    if ok and found then matches[#matches + 1] = pattern end
  end

  return matches
end

--- @param cmd string
--- @return boolean
function M.is_risky(cmd)
  local config = require("cmdlog.config")
  if not config.options.highlight_risky then return false end

  return #M.matching(cmd) > 0
end

return M
