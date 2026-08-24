---@module 'cmdlog.ui.mappings'
--- Factory for a Telescope attach_mappings function.

local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.mappings]")

--- Creates a Telescope attach_mappings function.
--- Keys are read from `config.options.mappings` (select/toggle_favorite/refresh/
--- delete/tag/note/show_note), so users can remap or disable (set to `false`) any of them.
--- @param refresh_fn function Function to refresh the picker
--- @param delete_fn? fun(cmd: string, on_done: fun(ok: boolean, err: string|nil), opts?: { skip_confirm?: boolean }) Deletes `cmd`
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

    -- Multi-select. Telescope's own default for this is <Tab>, which is
    -- already toggle_favorite here, so it needs its own key. Pairing the
    -- toggle with a move is telescope's standard idiom: marking a run of
    -- entries otherwise means alternating between two keys.
    if mappings.toggle_selection then
      map("i", mappings.toggle_selection, function()
        actions.toggle_selection(prompt_bufnr)
        actions.move_selection_worse(prompt_bufnr)
      end)
    end

    if mappings.delete and delete_fn then
      map("i", mappings.delete, function()
        local targets = {}

        -- Multi-selection wins when there is one; otherwise the entry under
        -- the cursor, which is what this key has always done.
        local picker = state.get_current_picker(prompt_bufnr)
        local multi = picker and picker:get_multi_selection() or {}
        if #multi > 0 then
          for _, entry in ipairs(multi) do
            if entry.value then targets[#targets + 1] = entry.value end
          end
        else
          local selected = state.get_selected_entry()
          if selected and selected.value then targets[1] = selected.value end
        end

        if #targets == 0 then return end

        ---Delete everything in `targets`, then close and refresh once.
        ---
        ---`skip_confirm` is passed for a batch because the batch has already
        ---been confirmed as a whole -- without it, deleting five entries
        ---would ask five separate questions.
        ---@param skip_confirm boolean
        local function run(skip_confirm)
          local remaining = #targets
          local deleted, failures = 0, {}

          local function finish()
            if deleted > 0 then
              actions.close(prompt_bufnr)
              vim.schedule(refresh_fn)
            end
            -- "cancelled" is the user's own answer to a confirmation, not a
            -- failure worth reporting back at them.
            local real = vim.tbl_filter(function(e)
              return e ~= "cancelled"
            end, failures)
            if #real > 0 then
              notify.warn(
                ("Could not delete %d of %d entr%s: %s"):format(
                  #real,
                  #targets,
                  #targets == 1 and "y" or "ies",
                  table.concat(real, "; ")
                )
              )
            end
          end

          for _, cmd in ipairs(targets) do
            delete_fn(cmd, function(ok, err)
              if ok then
                deleted = deleted + 1
              else
                failures[#failures + 1] = tostring(err or "unknown error")
              end
              remaining = remaining - 1
              if remaining == 0 then finish() end
            end, { skip_confirm = skip_confirm })
          end
        end

        if #targets == 1 then
          run(false)
          return
        end

        require("lib.nvim.ui.kit").confirm({
          question = ("Delete %d selected entries from their underlying history?"):format(#targets),
          on_answer = function(yes)
            if yes then run(true) end
          end,
        })
      end)
    end

    return true
  end
end
