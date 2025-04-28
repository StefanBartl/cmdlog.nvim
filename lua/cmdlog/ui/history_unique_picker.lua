local history = require("cmdlog.core.history")
local process_list = require("cmdlog.core.utils").process_list
local favorites = require("cmdlog.core.favorites")
local config = require("cmdlog.config")

local M = {}

--- Loads and shows a picker displaying unique command history entries.
--- Commands are deduplicated to show each command only once.
--- Favorites are highlighted but not prioritized at the top.
--- Supports Telescope and fzf as picker backends.
--- @return nil
function M.show_history_unique_picker()
  local entries = process_list(history.get_command_history(), { unique = true })
  local favs = favorites.load()

  if config.options.picker == "telescope" then
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
      previewer = require("cmdlog.ui.telescope-previewer").command_previewer(),
      attach_mappings = require("cmdlog.ui.mappings")(M.show_history_unique_picker),
    }):find()

  elseif config.options.picker == "fzf" then
    local fzf = require("fzf-lua")
    fzf.fzf_exec(entries, {
      prompt = ":history (unique)> ",
      previewer = require("cmdlog.ui.fzf-previewer").command_previewer(),
      actions = {
        ["default"] = function(selected)
          if selected[1] then
            vim.cmd(selected[1])
          end
        end,
      },
    })

  else
    vim.notify("[cmdlog] Unknown picker: " .. tostring(config.options.picker), vim.log.levels.ERROR)
  end
end

return M
