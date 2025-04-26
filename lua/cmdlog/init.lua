local config = require("cmdlog.config")

local M = {}

--- Setup function for the plugin
--- @param opts table|nil Optional user configuration
function M.setup(opts)
  -- Merge user options with defaults
  config.setup(opts)

  -- Register Telescope command
  local ok, picker = pcall(require, "cmdlog.ui.picker")
  if ok and picker.register_command then
    picker.register_command()
  else
    vim.notify("[nvim-cmdlog] Failed to load picker module", vim.log.levels.ERROR)
  end
end

return M
