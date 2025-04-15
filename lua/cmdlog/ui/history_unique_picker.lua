local history = require("cmdlog.core.history")
local favorites = require("cmdlog.core.favorites")

local M = {}

function M.show_history_unique_picker()
  local entries = history.process_history(history.get_command_history(), { unique = true })
  local favs = favorites.load()

  require("telescope.pickers").new({}, {
    prompt_title = ":history (unique)",
    finder = require("telescope.finders").new_table {
      results = entries,
      entry_maker = function(entry)
        local is_fav = vim.tbl_contains(favs, entry)
        return {
          value = entry,
          display = (is_fav and "★ " or "   ") .. entry,
          ordinal = entry,
        }
      end,
    },
    sorter = require("telescope.config").values.generic_sorter({}),
    previewer = require("cmdlog.ui.previewer").command_previewer(),
    attach_mappings = require("cmdlog.ui.mappings")(M.show_history_unique_picker),
  }):find()
end

return M
