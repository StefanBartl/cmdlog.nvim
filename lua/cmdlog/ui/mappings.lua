-- cmdlog/ui/mappings.lua

local M = {}

--- Creates a Telescope attach_mappings function
--- Handles <CR> to execute, <C-f> to toggle favorite, <C-r> to refresh
--- @param refresh_fn function Function to refresh the picker
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
        -- Feed the selected command back into the command-line
        vim.fn.feedkeys(":" .. selected.value, "n")
      end
    end)

    map("i", "<Tab>", function()
      local selected = state.get_selected_entry()
      if selected and selected.value then
        favorites.toggle(selected.value)
        actions.close(prompt_bufnr)
        vim.schedule(refresh_fn) -- Refresh the picker
      end
    end)

    map("i", "<C-r>", function()
      actions.close(prompt_bufnr)
      vim.schedule(refresh_fn) -- Refresh manually
    end)

    return true
  end
end
