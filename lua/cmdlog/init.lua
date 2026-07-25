local config = require("cmdlog.config")

local M = {}

--- Setup function for the plugin
--- @param opts table|nil Optional user configuration
function M.setup(opts)
  -- Merge user options with defaults
  config.setup(opts)

  -- Register command
  local ok, picker = pcall(require, "cmdlog.ui.picker")
  if ok and picker.register_command then
    picker.register_command()
  else
    vim.notify("[nvim-cmdlog] Failed to load picker module", vim.log.levels.ERROR)
  end

  -- Start recording ':' commands for project history, stats and error tracking
  require("cmdlog.core.tracker").setup()

  -- Optional which-key integration for :Cmdlog subcommands
  if config.options.keymaps and next(config.options.keymaps) then
    require("cmdlog.integrations.which_key").register(config.options.keymaps)
  end
end

return M
