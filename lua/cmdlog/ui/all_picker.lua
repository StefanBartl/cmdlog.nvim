local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- Loads and shows a picker that combines favorites and all history entries.
--- Favorites are always shown at the top.
--- Supports Telescope and fzf as picker backends.
--- @return nil
function M.show_all_picker()
  local favs = favorites.load()
  local raw = history.get_command_history()
  local hist = process_list(raw, { unique = false })

  local combined = vim.list_extend(vim.deepcopy(favs), hist)

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":history & favorites",
    fzf_prompt = ":history & favorites> ",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_all_picker),
  })
end

return M
