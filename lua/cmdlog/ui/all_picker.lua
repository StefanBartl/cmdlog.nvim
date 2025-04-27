local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")
local process_list = require("cmdlog.core.utils").process_list
local config = require("cmdlog.config")

local M = {}

function M.show_all_picker()
  local favs = favorites.load()
  local raw = history.get_command_history()
  local hist = process_list(raw, { unique = false })

  local combined = vim.list_extend(vim.deepcopy(favs), hist)

  if config.options.picker == "telescope" then
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
      previewer = require("cmdlog.ui.telescope-previewer").command_previewer(),
      attach_mappings = require("cmdlog.ui.mappings")(M.show_all_picker),
    }):find()

  elseif config.options.picker == "fzf" then
    local fzf = require("fzf-lua")
    fzf.fzf_exec(combined, {
      prompt = ":history & favorites> ",
      previewer = require("cmdlog.ui.fzf-previewer").command_previewer(),
      actions = {
        ["default"] = function(selected)
          if selected[1] then
            vim.fn.feedkeys(":" .. selected[1], "n")
          end
        end,
      },
    })

  else
    vim.notify("[cmdlog] Unknown picker: " .. tostring(config.options.picker), vim.log.levels.ERROR)
  end
end

return M
