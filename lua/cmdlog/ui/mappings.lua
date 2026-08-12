---@module 'cmdlog.ui.mappings'
--- Factory for a Telescope attach_mappings function.

local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.mappings]")

--- Creates a Telescope attach_mappings function.
--- Keys are read from `config.options.mappings` (select/toggle_favorite/refresh/
--- delete/tag/note/show_note), so users can remap or disable (set to `false`) any of them.
--- @param refresh_fn function Function to refresh the picker
--- @param delete_fn? fun(cmd: string, on_done: fun(ok: boolean, err: string|nil)) Deletes `cmd`
---        from its underlying history source (async: may show a confirmation dialog first);
---        `on_done` receives `ok` and an optional error message. Pickers that have no sensible
---        delete target (e.g. the favorites picker, where <Tab> already removes) can omit this
---        — the delete mapping is then simply not bound.
--- @param opts? { tag?: boolean, reorder?: boolean, favorite_note?: boolean } `tag = true` binds
---        `mappings.tag` to prompt for a tag and attach it to the selected command. `reorder =
---        true` binds `mappings.move_favorite_up/down` to swap the selected favorite's position
---        in the persisted order. `favorite_note = true` binds `mappings.note` (add/edit, blank
---        input deletes) and `mappings.show_note` (peek in a floating popup). All three are set
---        only by the favorites picker: tags/notes/reordering are stored per favorite, so
---        applying them to a command that is not one has nothing to attach to.
--- @return function
return function(refresh_fn, delete_fn, opts)
  return function(prompt_bufnr, map)
    local actions = require("telescope.actions")
    local state = require("telescope.actions.state")
    local favorites = require("cmdlog.core.favorites")
    local mappings = require("cmdlog.config").options.mappings

    if not mappings.enabled then return true end

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

    if mappings.undo_favorite then
      map("i", mappings.undo_favorite, function()
        if favorites.undo_last_toggle() then
          actions.close(prompt_bufnr)
          vim.schedule(refresh_fn)
        else
          notify.info("Nothing to undo")
        end
      end)
    end

    if mappings.move_favorite_up and opts and opts.reorder then
      map("i", mappings.move_favorite_up, function()
        local selected = state.get_selected_entry()
        if selected and selected.value and favorites.move(selected.value, -1) then
          actions.close(prompt_bufnr)
          vim.schedule(refresh_fn)
        end
      end)
    end

    if mappings.move_favorite_down and opts and opts.reorder then
      map("i", mappings.move_favorite_down, function()
        local selected = state.get_selected_entry()
        if selected and selected.value and favorites.move(selected.value, 1) then
          actions.close(prompt_bufnr)
          vim.schedule(refresh_fn)
        end
      end)
    end

    if mappings.tag and opts and opts.tag then
      map("i", mappings.tag, function()
        local selected = state.get_selected_entry()
        if not selected or not selected.value then return end
        vim.ui.input({ prompt = "Add tag: " }, function(tag)
          if tag and tag ~= "" then
            require("cmdlog.core.tags").add_tag(selected.value, tag)
            actions.close(prompt_bufnr)
            vim.schedule(refresh_fn)
          end
        end)
      end)
    end

    if mappings.note and opts and opts.favorite_note then
      map("i", mappings.note, function()
        local selected = state.get_selected_entry()
        if not selected or not selected.value then return end
        local favorite_notes = require("cmdlog.core.favorite_notes")
        vim.ui.input({
          prompt = "Note (blank removes it): ",
          default = favorite_notes.get_note(selected.value) or "",
        }, function(input)
          if input == nil then return end -- cancelled (<Esc>), leave the note as-is
          favorite_notes.set_note(selected.value, input)
          actions.close(prompt_bufnr)
          vim.schedule(refresh_fn)
        end)
      end)
    end

    if mappings.show_note and opts and opts.favorite_note then
      map("i", mappings.show_note, function()
        local selected = state.get_selected_entry()
        if not selected or not selected.value then return end
        local favorite_notes = require("cmdlog.core.favorite_notes")
        require("cmdlog.ui.note_popup").show(
          selected.value,
          favorite_notes.get_note(selected.value)
        )
      end)
    end

    if mappings.delete and delete_fn then
      map("i", mappings.delete, function()
        local selected = state.get_selected_entry()
        if not selected or not selected.value then return end

        delete_fn(selected.value, function(ok, err)
          if ok then
            actions.close(prompt_bufnr)
            vim.schedule(refresh_fn)
          elseif err and err ~= "cancelled" then
            notify.warn("Could not delete entry: " .. tostring(err))
          end
        end)
      end)
    end

    return true
  end
end
