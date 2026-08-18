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
---
--- A fourth, Telescope-only decoration is `opts.sections` (see
--- `M.section_dividers`): non-selectable "── nvim history ──"-style header
--- rows spliced between origin blocks in the combined pickers (`all_picker`/
--- `all_unique_picker`), so it's obvious at a glance where the shell block
--- ends and the nvim block begins, without reading every `[nvim]`/`[shell]`
--- suffix. Meaningful only while the prompt is empty -- see the entry_maker
--- comment below.

local config = require("cmdlog.config")
local errors = require("cmdlog.core.errors")
local notes = require("cmdlog.core.notes")
local risky = require("cmdlog.core.risky")

---@class CmdlogSectionMarker
---@field __cmdlog_section string Label shown on the divider row, e.g. "nvim history"

local M = {}

--- The notes side window of the picker that is currently open, if any.
--- Tracked module-wide so a re-opened picker (every <Tab>/refresh closes and
--- re-opens one) reuses/replaces it instead of stacking a new vsplit next to
--- the leftover one.
---@internal
---@type number|nil
local active_notes_win = nil

--- Closes the notes side window left over from a previous picker, if it is
--- still around.
---@internal
local function close_notes_window()
  if active_notes_win and vim.api.nvim_win_is_valid(active_notes_win) then
    vim.api.nvim_win_close(active_notes_win, true)
  end
  active_notes_win = nil
end

--- Opens the notes side window, if notes are enabled.
---
--- Must be called *before* Telescope's `:find()`: `vsplit` leaves the current
--- window, and Telescope closes the picker (wiping `prompt_bufnr`) as soon as
--- its prompt buffer is left. Opening it from inside `attach_mappings` is what
--- made the follow-up `nvim_buf_attach` fail with "Invalid buffer id".
--- Focus is restored to the caller's window so the picker still opens where
--- the user was.
---@internal
---@return number|nil win
local function open_notes_window()
  if not config.options.notes or not config.options.notes.enabled then return nil end

  close_notes_window()

  local prev = vim.api.nvim_get_current_win()
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_width(win, config.options.notes.width)
  vim.api.nvim_set_option_value("number", false, { win = win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = win })
  vim.api.nvim_set_option_value("wrap", true, { win = win })

  if vim.api.nvim_win_is_valid(prev) then vim.api.nvim_set_current_win(prev) end

  active_notes_win = win
  return win
end

--- Whether `entry` is a section-divider pseudo-entry inserted by
--- `M.open_picker` from `opts.sections`, rather than a real history/favorite
--- string. Checked by shape, not value, so it can never collide with an
--- actual command.
---@internal
---@param entry string|CmdlogSectionMarker
---@return boolean
local function is_section_marker(entry)
  if type(entry) ~= "table" then return false end
  ---@cast entry CmdlogSectionMarker
  return entry.__cmdlog_section ~= nil
end

--- Builds the Telescope entry_maker: favorite/known-bad marker, optional
--- label suffix, and risky-command highlighting.
---@internal
---@param favs string[]
---@param opts table
---@return fun(entry: string|CmdlogSectionMarker): table
local function make_entry_maker(favs, opts)
  return function(entry)
    if is_section_marker(entry) then
      ---@cast entry CmdlogSectionMarker
      local text = ("── %s "):format(entry.__cmdlog_section)
      text = text .. string.rep("─", math.max(0, 40 - vim.fn.strdisplaywidth(text)))
      return {
        -- `value = false` is the whole trick: every action in ui/mappings.lua
        -- guards on `selected.value` before doing anything, so a divider
        -- is inert (select/favorite/tag/delete/etc. all silently no-op) with
        -- no per-action special-casing needed. An empty ordinal means the
        -- fuzzy sorter drops it out of view as soon as you start typing --
        -- it only means something while browsing the unfiltered list, which
        -- is also the only time the block boundaries it marks are stable.
        value = false,
        ordinal = "",
        display = function()
          return text, { { { 0, #text }, "CmdlogSectionDivider" } }
        end,
      }
    end
    ---@cast entry string

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
    { mappings.note, "note" },
    { mappings.show_note, "peek note" },
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

--- Computes divider positions for `M.open_picker`'s `opts.sections`, given
--- the ordered list of origin blocks a combined picker concatenated into its
--- `entries` array (e.g. favorites, then nvim, then shell, then extra).
--- Returns `nil` when fewer than two blocks are actually non-empty — a
--- single-origin list has no boundary to mark.
---@param blocks { label: string, count: integer }[]
---@return { at: integer, label: string }[]|nil
function M.section_dividers(blocks)
  local non_empty = 0
  for _, block in ipairs(blocks) do
    if block.count > 0 then non_empty = non_empty + 1 end
  end
  if non_empty < 2 then return nil end

  local sections = {}
  local index = 1
  for _, block in ipairs(blocks) do
    if block.count > 0 then
      table.insert(sections, { at = index, label = block.label })
      index = index + block.count
    end
  end
  return sections
end

--- Opens a picker (Telescope or fzf-lua) based on configuration.
--- @param entries string[] List of entries (already combined if needed)
--- @param favs string[] List of favorite commands
--- @param opts table Options: prompt_title, fzf_prompt, attach_mappings, actions.
---   `opts.label(entry)` may return an extra string appended to the display
---   (Telescope only). `opts.sections` (as returned by `M.section_dividers`)
---   inserts non-selectable divider rows at the given 1-based indices into
---   `entries` (Telescope only).
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

  -- Splice section-divider pseudo-entries into a *copy* of `entries` for the
  -- Telescope finder only -- `entries` itself stays untouched so the fzf
  -- branch above (and anything the caller does with it) never sees them.
  ---@type (string|CmdlogSectionMarker)[]
  local results = entries
  if opts.sections and #opts.sections > 0 then
    results = {}
    local label_at = {}
    for _, section in ipairs(opts.sections) do
      label_at[section.at] = section.label
    end
    for i, entry in ipairs(entries) do
      if label_at[i] then table.insert(results, { __cmdlog_section = label_at[i] }) end
      table.insert(results, entry)
    end
  end

  -- Opened before the picker on purpose -- see open_notes_window.
  local notes_win = open_notes_window()

  pickers
    .new({}, {
      prompt_title = (opts.prompt_title or ":commands") .. build_legend(),
      default_text = opts.default_text,
      finder = finders.new_table({
        results = results,
        entry_maker = make_entry_maker(favs, opts),
      }),
      sorter = conf.generic_sorter({}),
      previewer = require("cmdlog.ui.telescope-previewer").command_previewer(),

      attach_mappings = function(prompt_bufnr, map)
        local function sync_notes()
          if not notes_win or not vim.api.nvim_win_is_valid(notes_win) then return end

          local entry = action_state.get_selected_entry()
          -- `entry.value == false` for a section divider (see
          -- make_entry_maker) -- nothing to show a note for.
          if not entry or not entry.value then return end

          local buf = notes.open(entry.value)
          if buf and vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_win_set_buf(notes_win, buf)
          end
        end

        -- Initial buffer fill
        sync_notes()

        -- Follow the selection as the prompt changes
        if vim.api.nvim_buf_is_valid(prompt_bufnr) then
          vim.api.nvim_buf_attach(prompt_bufnr, false, {
            on_lines = function()
              vim.schedule(sync_notes)
            end,
            on_detach = function() end,
          })
        end

        if notes_win then
          -- Tear the side window down whenever the prompt buffer goes away,
          -- not just on <CR>: <Esc>, <Tab> (toggle favorite) and refresh all
          -- close the picker without going through select_default, and would
          -- otherwise leave an orphaned split behind.
          vim.api.nvim_create_autocmd("BufWipeout", {
            buffer = prompt_bufnr,
            once = true,
            callback = function()
              if config.options.notes.persist then return end
              vim.schedule(function()
                -- Only if a re-opened picker has not already claimed a fresh
                -- window in the meantime (<Tab> closes then re-opens).
                if active_notes_win == notes_win then close_notes_window() end
              end)
            end,
          })

          actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            if not config.options.notes.persist and active_notes_win == notes_win then
              close_notes_window()
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
