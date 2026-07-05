---@module 'cmdlog.bindings'
--- Aggregator + registration entry point for every command/keymap cmdlog owns.
--- See docs/BINDINGS.md for the human-readable version of this catalog.

local M = {}

--- Registers user commands and (if enabled) optional entry-point keymaps.
--- @return nil
function M.register()
  require("cmdlog.bindings.usrcmds").register()
  require("cmdlog.bindings.keymaps").register()
end

--- Returns a machine-readable snapshot of every command/keymap/autocmd.
--- Handy for introspection, e.g. `:lua vim.print(require("cmdlog.bindings").catalog())`.
--- @return table
function M.catalog()
  return {
    usrcmds = require("cmdlog.bindings.usrcmds").catalog,
    keymaps = require("cmdlog.bindings.keymaps").catalog,
    picker_mappings = require("cmdlog.bindings.picker_mappings").resolved(),
    autocmds = require("cmdlog.bindings.autocmds").catalog,
  }
end

return M
