local config = require("cmdlog.config")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim]")

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
    notify.error("Failed to register bindings: " .. tostring(err))
  end

  -- Start recording ':' commands for project history, stats and error
  -- tracking. Opt-out via `track_commands = false`.
  if config.options.track_commands ~= false then
    require("cmdlog.core.tracker").setup()
  end

  -- Optional which-key integration for the :Cmdlog subcommand keymaps.
  -- bindings.keymaps already sets a `desc` on each mapping, which which-key
  -- v3+ reads on its own; this registers the group label on top.
  if type(config.options.keymaps) == "table" and next(config.options.keymaps) then
    require("cmdlog.integrations.which_key").register(config.options.keymaps)
  end

  -- Highlight group used for risky/destructive commands (see cmdlog.core.risky)
  vim.api.nvim_set_hl(0, "CmdlogRiskyCommand", { link = "DiagnosticError", default = true })
end

return M
