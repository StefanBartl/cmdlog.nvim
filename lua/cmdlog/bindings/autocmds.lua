---@module 'cmdlog.bindings.autocmds'
--- Descriptive catalog of autocmds cmdlog registers. Registers nothing itself —
--- the actual `nvim_create_autocmd` calls stay in lua/cmdlog/core/notes.lua
--- since they are buffer-local and created dynamically per note buffer.
--- This file exists so docs/BINDINGS.md has a single place to read from.

local M = {}

---@type {events: string[], scope: string, desc: string}[]
M.catalog = {
  {
    events = { "BufWritePost", "TextChanged", "TextChangedI" },
    scope = "note buffer (buffer-local)",
    desc = "Writes the note buffer's content to disk (see cmdlog.core.notes.attach_autosave)",
  },
}

return M
