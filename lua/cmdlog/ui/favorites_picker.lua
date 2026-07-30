local favorites = require("cmdlog.core.favorites")
local tags = require("cmdlog.core.tags")
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
    fzf_prompt = ":favorites> ",
    -- Show each favorite's tags next to it.
    label = function(cmd)
      local cmd_tags = tags.get_tags(cmd)
      return #cmd_tags > 0 and table.concat(cmd_tags, ", ") or nil
    end,
    -- Mappings come from the shared module rather than being hand-rolled
    -- here, so they honour `config.options.mappings` like every other
    -- picker. `tag = true` opts this picker into the tag mapping; no delete
    -- function is passed because <Tab> already removes a favorite.
    attach_mappings = require("cmdlog.ui.mappings")(M.show_favorites_picker, nil, { tag = true }),
  })
end

return M
