local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

function M.show_history_picker()
  local favs = favorites.load()
  local raw = history.get_command_history()
  local entries = process_list(raw, { unique = false })

  local combined = vim.list_extend(vim.deepcopy(favs), entries)

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":history (all)",
    fzf_prompt = ":history (all)> ",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_history_picker),
  })
end

return M
