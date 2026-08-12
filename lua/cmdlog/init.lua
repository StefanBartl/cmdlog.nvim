---@module 'cmdlog'
--- Plugin entry point: merges user config, registers bindings, starts the
--- command tracker and wires up optional which-key integration.

local config = require("cmdlog.config")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim]")

local M = {}

--- Setup function for the plugin
--- @param opts table|nil Optional user configuration
--- @return nil
function M.setup(opts)
  -- Merge user options with defaults
  config.setup(opts)

  -- Register user commands and optional entry-point keymaps
  local ok, err = pcall(function()
    require("cmdlog.bindings").register()
  end)
  if not ok then notify.error("Failed to register bindings: " .. tostring(err)) end

  -- Start recording ':' commands for project history, stats and error
  -- tracking. Opt-out via `track_commands = false`.
  if config.options.track_commands ~= false then require("cmdlog.core.tracker").setup() end

  -- Optional which-key integration for the :Cmdlog subcommand keymaps.
  -- bindings.register() above already called bindings.keymaps.register(),
  -- which sets a `desc` on each mapping -- which-key v3+ picks that up on
  -- its own. This call only feeds the same specs through wk.add() so they
  -- also show up in which-key's own registry/tree view.
  if type(config.options.keymaps) == "table" and next(config.options.keymaps) then
    require("cmdlog.integrations.which_key").register(config.options.keymaps)
  end

  -- Highlight group used for risky/destructive commands (see cmdlog.core.risky)
  vim.api.nvim_set_hl(0, "CmdlogRiskyCommand", { link = "DiagnosticError", default = true })

  -- Highlight group for the "── nvim history ──" divider rows in the
  -- combined pickers (see cmdlog.ui.picker_utils' opts.sections)
  vim.api.nvim_set_hl(0, "CmdlogSectionDivider", { link = "Comment", default = true })
end

return M
