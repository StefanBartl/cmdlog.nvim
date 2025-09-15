--- @module 'cmdlog.ui.favorites_picker'
--- @brief Zeigt alle Favoriten an (aus JSON), inkl. Ausführen/Toggle im Picker.

local favorites = require("cmdlog.core.favorites")
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- Loads and shows a picker displaying all favorite commands.
--- Allows executing a command or toggling its favorite status directly from the picker.
--- Supports Telescope and fzf as picker backends.
--- @return nil
function M.show_favorites_picker()
  local favs = favorites.load()

  if #favs == 0 then
    vim.notify("[nvim-cmdlog] No favorites found", vim.log.levels.INFO)
    return
  end

  picker_utils.open_picker(favs, favs, {
    prompt_title = ":history (Favorites)",
    fzf_prompt = ":favorites> ",
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      -- Enter: ausführen
      map("i", "<CR>", function()
        local selected = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selected and selected.value then
          vim.fn.feedkeys(":" .. selected.value, "n")
        end
      end)

      -- Tab: toggle + neu laden
      map("i", "<Tab>", function()
        local selected = action_state.get_selected_entry()
        if selected and selected.value then
          favorites.toggle(selected.value)
          actions.close(prompt_bufnr)
          vim.schedule(M.show_favorites_picker)
        end
      end)

      return true
    end,
    actions = {
      ["default"] = function(selected)
        if selected[1] then
          vim.fn.feedkeys(":" .. selected[1], "n")
        end
      end,
      ["ctrl-f"] = function(selected)
        if selected[1] then
          favorites.toggle(selected[1])
          vim.schedule(M.show_favorites_picker)
        end
      end,
    },
  })
end

return M
