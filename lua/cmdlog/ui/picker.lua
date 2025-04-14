local history = require("cmdlog.core.history")

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

  require("telescope.pickers").new({}, {
    prompt_title = ":history",
    finder = require("telescope.finders").new_table {
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry,
          ordinal = entry,
        }
      end,
    },
    sorter = require("telescope.config").values.generic_sorter({}),
    attach_mappings = function(_, map)
      map("i", "<CR>", function(prompt_bufnr)
        local action_state = require("telescope.actions.state")
        local selected = action_state.get_selected_entry()
        require("telescope.actions").close(prompt_bufnr)

        if selected and selected.value then
          vim.fn.feedkeys(":" .. selected.value, "n")
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
