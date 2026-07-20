local favorites = require("cmdlog.core.favorites")
local picker_utils = require("cmdlog.ui.picker_utils")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.favorites_picker]")

local M = {}

--- Loads and shows a picker displaying all favorite commands.
--- Allows executing a command or toggling its favorite status directly from the picker.
--- Supports Telescope and fzf as picker backends.
--- @return nil
function M.show_favorites_picker()
  local favs = favorites.load()

  if #favs == 0 then
    notify.info("No favorites found")
    return
  end

  picker_utils.open_picker(favs, favs, {
    prompt_title = ":history (Favorites)",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_favorites_picker),
  })
end

return M
