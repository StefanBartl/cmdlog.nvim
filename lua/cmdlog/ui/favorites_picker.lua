---@module 'cmdlog.ui.favorites_picker'
--- Picker showing favorited commands, with tags and a toggle-favorite mapping.

local favorites = require("cmdlog.core.favorites")
local tags = require("cmdlog.core.tags")
local favorite_notes = require("cmdlog.core.favorite_notes")
local picker_utils = require("cmdlog.ui.picker_utils")
local cycle = require("cmdlog.ui.cycle")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.favorites_picker]")

local M = {}

--- Loads and shows a picker displaying all favorite commands.
--- Allows executing a command or toggling its favorite status directly from the picker.
--- Supports Telescope and fzf as picker backends.
--- @param initial_text? string Prompt text to pre-fill, used by `mappings.cycle_source`
--- @return nil
function M.show_favorites_picker(initial_text)
  local favs = favorites.load()

  if #favs == 0 then
    notify.info("No favorites found")
    return
  end

  picker_utils.open_picker(favs, favs, {
    prompt_title = ":history (Favorites)",
    fzf_prompt = ":favorites> ",
    default_text = initial_text,
    -- Show each favorite's tags next to it, plus a "📝" marker (not the
    -- note text itself -- mappings.show_note peeks the full text on demand)
    -- when it carries a note, so a note's presence is discoverable without
    -- cluttering every line with its content.
    label = function(cmd)
      local parts = {}
      local cmd_tags = tags.get_tags(cmd)
      if #cmd_tags > 0 then table.insert(parts, table.concat(cmd_tags, ", ")) end
      if favorite_notes.get_note(cmd) then table.insert(parts, "📝") end
      return #parts > 0 and table.concat(parts, "  ") or nil
    end,
    -- Mappings come from the shared module rather than being hand-rolled
    -- here, so they honour `config.options.mappings` like every other
    -- picker. `tag = true` opts this picker into the tag mapping; `reorder
    -- = true` binds move_favorite_up/down (only meaningful here, where
    -- order is manually curated); `favorite_note = true` binds the
    -- add/edit-note and peek-note mappings (same reasoning); no delete
    -- function is passed because <Tab> already removes a favorite.
    attach_mappings = function(prompt_bufnr, map)
      cycle.attach(prompt_bufnr, map, "favorites")
      return require("cmdlog.ui.mappings")(
        M.show_favorites_picker,
        nil,
        { tag = true, reorder = true, favorite_note = true }
      )(prompt_bufnr, map)
    end,
  })
end

return M
