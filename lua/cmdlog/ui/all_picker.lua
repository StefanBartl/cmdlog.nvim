local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")

local M = {}

function M.show_all_picker()
  local favs = favorites.load()
  local raw = history.get_command_history()
  local hist = history.process_history(raw, { unique = false })

  local combined = vim.list_extend(vim.deepcopy(favs), hist)

  require("telescope.pickers").new({}, {
    prompt_title = ":history & favorites",
    finder = require("telescope.finders").new_table {
      results = combined,
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
    attach_mappings = require("cmdlog.ui.mappings")(M.show_all_picker),
  }):find()
end

return M
