--- @module 'cmdlog.ui.mappings'
--- @brief Telescope keymaps für Ausführen/Toggle/Refresh im Picker.

--- Creates a Telescope attach_mappings function
--- Handles <CR> to execute, <Tab> to toggle favorite, <C-r> to refresh
--- @param refresh_fn fun():nil  Function to refresh the picker
--- @return fun(prompt_bufnr: integer, map: fun(mode:string, lhs:string, rhs:function, opts?:table):nil)
return function(refresh_fn)
  return function(prompt_bufnr, map)
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local favorites = require("cmdlog.core.favorites")

    -- Enter: Befehl ausführen
    map("i", "<CR>", function()
      local selected = state.get_selected_entry()
      actions.close(prompt_bufnr)
      if selected and selected.value then
        -- korrekt konkatenieren
        vim.fn.feedkeys(":" .. selected.value, "n")
      end
    end)

    -- Tab: Favorite toggeln + neu laden
    map("i", "<Tab>", function()
      local selected = state.get_selected_entry()
      if selected and selected.value then
        favorites.toggle(selected.value)
        actions.close(prompt_bufnr)
        vim.schedule(refresh_fn)
      end
    end)

    -- <C-r>: Manuell refreshen
    map("i", "<C-r>", function()
      actions.close(prompt_bufnr)
      vim.schedule(refresh_fn)
    end)

    return true
  end
end
