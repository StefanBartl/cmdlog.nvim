local history_picker = require("cmdlog.ui.history_picker")
local favorites_picker = require("cmdlog.ui.favorites_picker")

local M = {}

function M.register_command()
  vim.api.nvim_create_user_command("Cmdlog", history_picker.show_history_picker, {})
  vim.api.nvim_create_user_command("CmdlogFavorites", favorites_picker.show_favorites_picker, {})
end

return M
