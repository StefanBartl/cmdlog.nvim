---@module 'cmdlog.core.risky'
--- Detects commands that are prone to causing damage or data loss, so
--- pickers can highlight them (see cmdlog.ui.picker_utils).

local M = {}

--- @param cmd string
--- @return boolean
function M.is_risky(cmd)
  local config = require("cmdlog.config")
  if not config.options.highlight_risky then return false end

  local patterns = config.options.risky_patterns
  if type(patterns) ~= "table" then return false end

  for _, pattern in ipairs(patterns) do
    if cmd:find(pattern) then return true end
  end

  return false
end

return M
