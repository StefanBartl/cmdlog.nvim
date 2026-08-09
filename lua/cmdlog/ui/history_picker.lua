---@module 'cmdlog.ui.history_picker'
--- Picker showing Neovim command-line history and favorites, duplicates included.

local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")
local extra_files = require("cmdlog.core.extra_files")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- Loads and shows a picker with favorites followed by the full (non-deduplicated)
--- Neovim `:` command-line history.
---@return nil
function M.show_history_picker()
  local favs = favorites.load()
  local raw = history.get_command_history()
  local entries = process_list(raw, { unique = false })

  local combined = vim.list_extend(vim.deepcopy(favs), entries)
  combined = vim.list_extend(combined, extra_files.get_history())

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":history (all)",
    fzf_prompt = ":history (all)> ",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_history_picker, history.delete_entry),
  })
end

return M
