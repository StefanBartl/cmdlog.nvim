local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")
local config = require("cmdlog.config")

local M = {}

function M.show_all_unique_picker()
  local favs = favorites.load()
  local raw = history.get_command_history()
  local hist = history.process_history(raw, { unique = true })

  local set = {}
  for _, f in ipairs(favs) do
    set[f] = true
  end

  local rest = {}
  for _, h in ipairs(hist) do
    if not set[h] then
      table.insert(rest, h)
    end
  end

  local combined = vim.list_extend(vim.deepcopy(favs), rest)

  if config.options.picker == "telescope" then
    require("telescope.pickers").new({}, {
      prompt_title = ":history & favorites (unique)",
      finder = require("telescope.finders").new_table {
        results = combined,
        entry_maker = function(entry)
          local is_fav = set[entry] or vim.tbl_contains(favs, entry)
          return {
            value = entry,
            display = (is_fav and "★ " or "   ") .. entry,
            ordinal = entry,
          }
        end,
      },
      sorter = require("telescope.config").values.generic_sorter({}),
      previewer = require("cmdlog.ui.telescope-previewer").command_previewer(),
      attach_mappings = require("cmdlog.ui.mappings")(M.show_all_unique_picker),
    }):find()

  elseif config.options.picker == "fzf" then
    local fzf = require("fzf-lua")
    fzf.fzf_exec(combined, {
      prompt = ":history & favorites (unique)> ",
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
