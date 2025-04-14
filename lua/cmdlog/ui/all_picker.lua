local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")

local M = {}

function M.show_all_picker()
  local favs = favorites.load()
  local raw = history.get_command_history()
  local hist = history.process_history(raw)

  -- Entferne Duplikate (Favoriten schon oben)
  local set = {}
  for _, cmd in ipairs(favs) do set[cmd] = true end

  local rest = {}
  for _, cmd in ipairs(hist) do
    if not set[cmd] then
      table.insert(rest, cmd)
    end
  end

  local combined = vim.list_extend(vim.deepcopy(favs), rest)

  require("telescope.pickers").new({}, {
    prompt_title = "★ All Commands",
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
          vim.schedule(M.show_all_picker)
        end
      end)

      return true
    end,
  }):find()
end

return M
