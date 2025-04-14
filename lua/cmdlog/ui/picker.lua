local history = require("cmdlog.core.history")
local favorites = require("cmdlog.core.favorites")

local M = {}

--- Open Telescope picker to view processed command-line history
function M.show_history_picker()
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    vim.notify("[nvim-cmdlog] telescope.nvim is not installed", vim.log.levels.ERROR)
    return
  end

  local raw = history.get_command_history()
  local entries = history.process_history(raw)

  local favs = favorites.load()

  require("telescope.pickers").new({}, {
    prompt_title = ":history",
    finder = require("telescope.finders").new_table {
      results = entries,
      entry_maker = function(entry)
        local is_fav = false
        for _, fav in ipairs(favs) do
          if fav == entry then
            is_fav = true
            break
          end
        end

        return {
          value = entry,
          display = (is_fav and "★ " or "   ") .. entry,
          ordinal = entry,
        }
      end,
    },
    sorter = require("telescope.config").values.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      -- Insert command into :
      map("i", "<CR>", function()
        local selected = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selected and selected.value then
          vim.fn.feedkeys(":" .. selected.value, "n")
        end
      end)

      -- Toggle favorite
      map("i", "<C-f>", function()
        local selected = action_state.get_selected_entry()
        if selected and selected.value then
          favorites.toggle(selected.value)
          -- re-open picker to refresh view
          actions.close(prompt_bufnr)
          vim.schedule(M.show_history_picker)
        end
      end)

      return true
    end,
  }):find()
end

--- Register the :Cmdlog command
function M.register_command()
  vim.api.nvim_create_user_command("Cmdlog", M.show_history_picker, {})
end

return M
