local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- Loads and shows a picker displaying unique command history entries.
--- Commands are deduplicated to show each command only once.
--- Favorites are highlighted but not prioritized at the top.
--- Supports Telescope and fzf as picker backends.
--- @return nil
function M.show_history_unique_picker()
  local favs = favorites.load()
  local raw = history.get_command_history()
  local entries = process_list(raw, { unique = true })

  local combined = vim.list_extend(vim.deepcopy(favs), entries)

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":history (unique)",
    fzf_prompt = ":history (unique)> ",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_history_unique_picker),
  })
end

return M
