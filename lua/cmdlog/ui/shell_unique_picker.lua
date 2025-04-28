local favorites = require("cmdlog.core.favorites")
local shell_mod = require("cmdlog.core.shell")
local process_list = require("cmdlog.core.utils").process_list
local config = require("cmdlog.config")

local M = {}

function M.show_shell_unique_picker()
  local favs = favorites.load()
  local raw = shell_mod.get_shell_history()
  local shell_cmds = process_list(raw, { unique = true })

  local combined = vim.list_extend(vim.deepcopy(favs), shell_cmds)

  if config.options.picker == "telescope" then
    require("telescope.pickers").new({}, {
      prompt_title = ":shell & favorites (unique)",
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
      attach_mappings = require("cmdlog.ui.mappings")(M.show_shell_unique_picker),
    }):find()

  elseif config.options.picker == "fzf" then
    local fzf = require("fzf-lua")
    fzf.fzf_exec(combined, {
      prompt = ":shell & favorites (unique)> ",
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
