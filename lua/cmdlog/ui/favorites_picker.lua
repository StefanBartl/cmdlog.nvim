local favorites = require("cmdlog.core.favorites")

local M = {}

function M.show_favorites_picker()
  local favs = favorites.load()

  if #favs == 0 then
    vim.notify("[nvim-cmdlog] No favorites found", vim.log.levels.INFO)
    return
  end

  require("telescope.pickers").new({}, {
    prompt_title = "★ Favorites",
    finder = require("telescope.finders").new_table {
      results = favs,
      entry_maker = function(entry)
        return {
          value = entry,
          display = "★ " .. entry,
          ordinal = entry,
        }
      end,
    },
    sorter = require("telescope.config").values.generic_sorter({}),
    previewer = require("cmdlog.ui.previewer").command_previewer(),
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      map("i", "<CR>", function()
        local selected = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selected and selected.value then
          vim.fn.feedkeys(":" .. selected.value, "n")
        end
      end)

      map("i", "<C-f>", function()
        local selected = action_state.get_selected_entry()
        if selected and selected.value then
          favorites.toggle(selected.value)
          actions.close(prompt_bufnr)
          vim.schedule(M.show_favorites_picker)
        end
      end)

      return true
    end,
  }):find()
end

return M
