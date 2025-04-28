local history_picker = require("cmdlog.ui.history_picker")
local unique_picker = require("cmdlog.ui.history_unique_picker")
local favorites_picker = require("cmdlog.ui.favorites_picker")
local all_picker = require("cmdlog.ui.all_picker")
local all_unique_picker = require("cmdlog.ui.all_unique_picker")
local shell_picker = require("cmdlog.ui.shell_picker")
local shell_unique_picker = require("cmdlog.ui.shell_unique_picker")

local M = {}

--- Registers user commands for various pickers like history, favorites, shell history, etc.
--- Commands are available as :Cmdlog, :CmdlogUnique, :CmdlogFavorites, :CmdlogAll, :CmdlogAllUnique, :CmdlogShell, and :CmdlogShellUnique.
--- @return nil
function M.register_command()
  vim.api.nvim_create_user_command("Cmdlog", history_picker.show_history_picker, {})
  vim.api.nvim_create_user_command("CmdlogUnique", unique_picker.show_history_unique_picker, {})
  vim.api.nvim_create_user_command("CmdlogFavorites", favorites_picker.show_favorites_picker, {})
  vim.api.nvim_create_user_command("CmdlogAll", all_picker.show_all_picker, {})
  vim.api.nvim_create_user_command("CmdlogAllUnique", all_unique_picker.show_all_unique_picker, {})
  vim.api.nvim_create_user_command("CmdlogShell", shell_picker.show_shell_picker, {})
  vim.api.nvim_create_user_command("CmdlogShellUnique", shell_unique_picker.show_shell_unique_picker, {})
end

return M
