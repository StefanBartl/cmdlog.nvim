-- cmdlog/ui/mappings.lua

local M = {}

--- Creates a Telescope attach_mappings function
--- Handles <CR>, <C-f>, and <C-r>
--- @param refresh_fn function
--- @return function
return function(refresh_fn)
  return function(prompt_bufnr, map)
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local favorites = require("cmdlog.core.favorites")

    map("i", "<CR>", function()
      local selected = state.get_selected_entry()
      actions.close(prompt_bufnr)
      if selected and selected.value then
        vim.fn.feedkeys(":" .. selected.value, "n")
      end
    end)

    map("i", "<C-f>", function()
      local selected = state.get_selected_entry()
      if selected and selected.value then
        favorites.toggle(selected.value)
        actions.close(prompt_bufnr)
        vim.schedule(refresh_fn)
      end
    end)

    map("i", "<C-r>", function()
      actions.close(prompt_bufnr)
      vim.schedule(refresh_fn)
    end)

    return true
  end
end
