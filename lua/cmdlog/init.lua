local config = require("cmdlog.config")

local M = {}

--- Setup function for the plugin
--- @param opts table|nil Optional user configuration
function M.setup(opts)
  -- Merge user options with defaults
  config.setup(opts)

  -- Register user commands and optional entry-point keymaps
  local ok, err = pcall(function()
    require("cmdlog.bindings").register()
  end)
  if not ok then
    vim.notify("[nvim-cmdlog] Failed to register bindings: " .. tostring(err), vim.log.levels.ERROR)
  end

  -- Highlight group used for risky/destructive commands (see cmdlog.core.risky)
  vim.api.nvim_set_hl(0, "CmdlogRiskyCommand", { link = "DiagnosticError", default = true })
end

return M
