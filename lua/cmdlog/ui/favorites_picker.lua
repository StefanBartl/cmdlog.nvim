---@module 'cmdlog.ui.favorites_picker'
--- Show/manage favorites with both Telescope and fzf-lua.

local favorites = require("cmdlog.core.favorites")
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

---@param s string
---@return string
local function unwrap_prefix(s)
  s = tostring(s or "")
  s = s:gsub("^%s*[★%*]%s+", "") -- star + space
  s = s:gsub("^%s%s%s", "")      -- three spaces
  return s
end

--- @return nil
function M.show_favorites_picker()
  local favs = favorites.load()
  if #favs == 0 then
    vim.notify("[nvim-cmdlog] No favorites found", vim.log.levels.INFO)
    return
  end

  picker_utils.open_picker(favs, favs, {
    prompt_title = ":history (Favorites)",
    fzf_prompt = ":favorites> ",

    -- Telescope mappings
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

      map("i", "<Tab>", function()
        local selected = action_state.get_selected_entry()
        if selected and selected.value then
          favorites.toggle(selected.value)
          actions.close(prompt_bufnr)
          vim.schedule(M.show_favorites_picker)
        end
      end)

      return true
    end,

    -- fzf-lua actions
    actions = {
      ["default"] = function(selected)
        if selected and selected[1] then
          local cmd = unwrap_prefix(selected[1])
          vim.fn.feedkeys(":" .. cmd, "n") -- FIX: '..'
        end
      end,
      ["tab"] = function(selected)
        if selected and selected[1] then
          local cmd = unwrap_prefix(selected[1])
          favorites.toggle(cmd)
          vim.schedule(M.show_favorites_picker) -- reopen with updated list
        end
      end,
      ["ctrl-f"] = function(selected)
        if selected and selected[1] then
          local cmd = unwrap_prefix(selected[1])
          favorites.toggle(cmd)
          vim.schedule(M.show_favorites_picker)
        end
      end,
    },
  })
end

return M
