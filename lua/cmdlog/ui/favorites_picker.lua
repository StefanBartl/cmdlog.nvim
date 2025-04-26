local favorites = require("cmdlog.core.favorites")
local config = require("cmdlog.config")

local M = {}

function M.show_favorites_picker()
  local favs = favorites.load()

  if #favs == 0 then
    vim.notify("[nvim-cmdlog] No favorites found", vim.log.levels.INFO)
    return
  end

  if config.options.picker == "telescope" then
    require("telescope.pickers").new({}, {
      prompt_title = ":history (Favorites)",
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
      previewer = require("cmdlog.ui.telescope-previewer").command_previewer(),
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

  elseif config.options.picker == "fzf" then
    local fzf = require("fzf-lua")
    fzf.fzf_exec(favs, {
      prompt = ":favorites> ",
      previewer = require("cmdlog.ui.fzf-previewer").command_previewer(),
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

  else
    vim.notify("[cmdlog] Unknown picker: " .. tostring(config.options.picker), vim.log.levels.ERROR)
  end
end

return M
