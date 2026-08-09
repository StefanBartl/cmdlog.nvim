---@module 'cmdlog.ui.picker_utils'
--- Picker abstraction (Telescope or fzf-lua) with optional notes integration.
---
--- Entries carry up to three independent decorations, all of which survived
--- the merge of the notes work into main:
---   ★ / ✗   favorite marker, or "known bad" if the command previously failed
---           (`core.errors`)
---   [tags]  whatever `opts.label(entry)` returns — the favorites picker uses
---           it to show a command's tags
---   colour  commands matching `risky_patterns` are highlighted with
---           `CmdlogRiskyCommand` (`core.risky`)
---
--- `errors.is_known_bad` and `risky.is_risky` are deliberately both applied:
--- one means "this failed when you ran it", the other "this is destructive by
--- nature". A command can be either, both, or neither.

local config = require("cmdlog.config")
local errors = require("cmdlog.core.errors")
local notes = require("cmdlog.core.notes")
local risky = require("cmdlog.core.risky")

local M = {}

--- Opens the notes side window, if notes are enabled.
---@internal
---@return number|nil win
local function open_notes_window()
  if not config.options.notes or not config.options.notes.enabled then return nil end

  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_width(win, config.options.notes.width)
  vim.api.nvim_set_option_value("number", false, { win = win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = win })
  vim.api.nvim_set_option_value("wrap", true, { win = win })

  return win
end

--- Builds the Telescope entry_maker: favorite/known-bad marker, optional
--- label suffix, and risky-command highlighting.
---@internal
---@param favs string[]
---@param opts table
---@return fun(entry: string): table
local function make_entry_maker(favs, opts)
  return function(entry)
    local is_fav = vim.tbl_contains(favs, entry)
    local is_bad = errors.is_known_bad(entry)
    local marker = is_bad and "✗ " or (is_fav and "★ " or "   ")
    local suffix = opts.label and opts.label(entry)
    suffix = suffix and ("  [" .. suffix .. "]") or ""

    return {
      value = entry,
      ordinal = entry,
      display = function(e)
        local text = marker .. e.value .. suffix
        -- A previously-failed command wins the colour: it is the more
        -- specific statement about this exact command.
        if is_bad then return text, { { { 0, #marker + #e.value }, "ErrorMsg" } } end
        if risky.is_risky(e.value) then
          return text, { { { 0, #marker + #e.value }, "CmdlogRiskyCommand" } }
        end
        return text
      end,
    }
  end
end

--- Builds a short "<key> action" legend from the configured mappings, shown
--- in the Telescope prompt title so the active keys are visible without
--- opening the docs. Generated from `config.options.mappings` rather than
--- hardcoded, since every mapping is user-configurable/disableable.
---@internal
---@return string
local function build_legend()
  local mappings = config.options.mappings
  if not mappings.enabled then return "" end

  local candidates = {
    { mappings.select, "select" },
    { mappings.toggle_favorite, "fav" },
    { mappings.refresh, "refresh" },
    { mappings.delete, "del" },
    { mappings.tag, "tag" },
    { mappings.cycle_source, "cycle" },
    { mappings.undo_favorite, "undo" },
  }

  local parts = {}
  for _, candidate in ipairs(candidates) do
    local key, label = candidate[1], candidate[2]
    if key then table.insert(parts, key .. " " .. label) end
  end

  return #parts > 0 and (" [" .. table.concat(parts, " | ") .. "]") or ""
end

--- Opens a picker (Telescope or fzf-lua) based on configuration.
--- @param entries string[] List of entries (already combined if needed)
--- @param favs string[] List of favorite commands
--- @param opts table Options: prompt_title, fzf_prompt, attach_mappings, actions.
---   `opts.label(entry)` may return an extra string appended to the display
---   (Telescope only).
--- @return nil
function M.open_picker(entries, favs, opts)
  opts = opts or {}

  if config.options.picker == "fzf" then
    -- fzf-lua entries double as the selected value (see the default action
    -- below), so decorating them the way the Telescope entry_maker does
    -- would corrupt `vim.cmd(selected[1])`. Marker/tag/risky decoration and
    -- the notes side window are therefore Telescope-only.
    local fzf = require("fzf-lua")
    fzf.fzf_exec(entries, {
      prompt = opts.fzf_prompt or ":commands> ",
      previewer = require("cmdlog.ui.fzf-previewer").command_previewer(),
      actions = opts.actions or {
        ["default"] = function(selected)
          if selected[1] then vim.cmd(selected[1]) end
        end,
      },
    })
    return
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers
    .new({}, {
      prompt_title = (opts.prompt_title or ":commands") .. build_legend(),
      default_text = opts.default_text,
      finder = finders.new_table({
        results = entries,
        entry_maker = make_entry_maker(favs, opts),
      }),
      sorter = conf.generic_sorter({}),
      previewer = require("cmdlog.ui.telescope-previewer").command_previewer(),

      attach_mappings = function(prompt_bufnr, map)
        local notes_win = open_notes_window()

        local function sync_notes()
          if not notes_win or not vim.api.nvim_win_is_valid(notes_win) then return end

          local entry = action_state.get_selected_entry()
          if not entry then return end

          local buf = notes.open(entry.value)
          if buf and vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_win_set_buf(notes_win, buf)
          end
        end

        -- Initial buffer fill
        sync_notes()

        -- Follow the selection as the prompt changes
        vim.api.nvim_buf_attach(prompt_bufnr, false, {
          on_lines = function()
            vim.schedule(sync_notes)
          end,
          on_detach = function() end,
        })

        if notes_win then
          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            if vim.api.nvim_win_is_valid(notes_win) and not config.options.notes.persist then
              vim.api.nvim_win_close(notes_win, true)
            end
          end)
        end

        -- Let the caller register its own mappings (select/toggle_favorite/
        -- refresh/delete/tag via cmdlog.ui.mappings, which honours
        -- config.options.mappings).
        if opts.attach_mappings then return opts.attach_mappings(prompt_bufnr, map) end

        return true
      end,
    })
    :find()
end

return M
