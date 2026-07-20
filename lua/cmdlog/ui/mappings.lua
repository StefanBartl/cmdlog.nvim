--- Creates a Telescope attach_mappings function.
--- Keys are read from `config.options.mappings` (select/toggle_favorite/refresh/delete),
--- so users can remap or disable (set to `false`) any of them.
--- @param refresh_fn function Function to refresh the picker
--- @param delete_fn? fun(cmd: string): boolean, string|nil Deletes `cmd` from its underlying
---        history source; returns `ok` and an optional error message. Pickers that have no
---        sensible delete target (e.g. the favorites picker, where <Tab> already removes) can
---        omit this — the delete mapping is then simply not bound.
--- @return function
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.mappings]")

return function(refresh_fn, delete_fn)
  return function(prompt_bufnr, map)
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local favorites = require("cmdlog.core.favorites")
    local mappings = require("cmdlog.config").options.mappings

    if not mappings.enabled then
      return true
    end

    if mappings.select then
      map("i", mappings.select, function()
        local selected = state.get_selected_entry()
        actions.close(prompt_bufnr)
        if selected and selected.value then
          -- Feed the selected command back into the command-line
          vim.fn.feedkeys(":" .. selected.value, "n")
        end
      end)
    end

    if mappings.toggle_favorite then
      map("i", mappings.toggle_favorite, function()
        local selected = state.get_selected_entry()
        if selected and selected.value then
          favorites.toggle(selected.value)
          actions.close(prompt_bufnr)
          vim.schedule(refresh_fn) -- Refresh the picker
        end
      end)
    end

    if mappings.refresh then
      map("i", mappings.refresh, function()
        actions.close(prompt_bufnr)
        vim.schedule(refresh_fn) -- Refresh manually
      end)
    end

    if mappings.delete and delete_fn then
      map("i", mappings.delete, function()
        local selected = state.get_selected_entry()
        if not selected or not selected.value then
          return
        end

        local ok, err = delete_fn(selected.value)
        if ok then
          actions.close(prompt_bufnr)
          vim.schedule(refresh_fn)
        elseif err and err ~= "cancelled" then
          vim.notify("[cmdlog.nvim] Could not delete entry: " .. tostring(err), vim.log.levels.WARN)
        end
      end)
    end

    return true
  end
end
