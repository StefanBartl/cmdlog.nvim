---@module 'cmdlog.bindings.usrcmds'
--- Single source of truth for every :Cmdlog* user command.
--- lua/cmdlog/ui/picker.lua used to hardcode this list directly; it now
--- delegates here so docs/BINDINGS.md and this file never drift apart.

local M = {}

---@type table<string, {desc: string, handler: fun()}>
M.catalog = {
  CmdlogNvimFull = {
    desc = "Show full Neovim (:) command history, including duplicates",
    handler = function() require("cmdlog.ui.history_picker").show_history_picker() end,
  },
  CmdlogNvim = {
    desc = "Show unique Neovim (:) command history (latest occurrence kept)",
    handler = function() require("cmdlog.ui.history_unique_picker").show_history_unique_picker() end,
  },
  CmdlogFull = {
    desc = "Show favorites and full history combined (duplicates allowed)",
    handler = function() require("cmdlog.ui.all_picker").show_all_picker() end,
  },
  Cmdlog = {
    desc = "Show favorites and history combined (unique commands only)",
    handler = function() require("cmdlog.ui.all_unique_picker").show_all_unique_picker() end,
  },
  CmdlogShellFull = {
    desc = "Show full shell history, including duplicates",
    handler = function() require("cmdlog.ui.shell_picker").show_shell_picker() end,
  },
  CmdlogShell = {
    desc = "Show unique shell history (latest occurrence kept)",
    handler = function() require("cmdlog.ui.shell_unique_picker").show_shell_unique_picker() end,
  },
  CmdlogFavorites = {
    desc = "Show commands marked as favorites",
    handler = function() require("cmdlog.ui.favorites_picker").show_favorites_picker() end,
  },
}

--- Registers every user command in `M.catalog`.
--- @return nil
function M.register()
  for name, entry in pairs(M.catalog) do
    vim.api.nvim_create_user_command(name, entry.handler, { desc = entry.desc })
  end
end

return M
