---@module 'cmdlog.ui.note_popup'
--- Transient floating-window "hover" for a favorite's note
--- (`mappings.show_note`, favorites picker only). Deliberately not the
--- persistent per-command notes side window `cmdlog.core.notes`/
--- `picker_utils.lua` open -- this just displays `cmdlog.core.favorite_notes`'
--- short text next to the cursor and closes itself on the next keystroke or
--- after a short timeout, with no buffer/file of its own.

local M = {}

--- @internal
--- @param lines string[]
--- @return integer width
local function max_width(lines)
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  return width
end

--- Shows `note` (or a placeholder if there is none) in a small floating
--- window anchored to the cursor. `focusable = false` so it never steals
--- focus from the picker prompt it was triggered from.
--- @param cmd string The favorite the note belongs to (used in the placeholder)
--- @param note string|nil
--- @return nil
function M.show(cmd, note)
  local lines = (note and note ~= "") and vim.split(note, "\n", { plain = true })
    or { ("(no note for '%s')"):format(cmd) }

  local width = math.max(10, math.min(max_width(lines) + 2, 80))
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = buf })

  local win = vim.api.nvim_open_win(buf, false, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = #lines,
    style = "minimal",
    border = "rounded",
    focusable = false,
    zindex = 250,
  })
  vim.api.nvim_set_option_value("wrap", true, { win = win })

  local closed = false
  local function close()
    if closed then return end
    closed = true
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end

  -- Any of these means "the user has moved on" -- close on the first one.
  vim.api.nvim_create_autocmd(
    { "CursorMovedI", "InsertCharPre", "BufLeave", "WinLeave", "ModeChanged" },
    { once = true, callback = close }
  )
  vim.defer_fn(close, 4000)
end

return M
