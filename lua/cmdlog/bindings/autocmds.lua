---@module 'cmdlog.bindings.autocmds'
--- Descriptive catalog of autocmds cmdlog registers. Registers nothing itself —
--- it exists so docs/BINDINGS.md (and `require("cmdlog.bindings").catalog()`)
--- have a single place to read from. Currently empty: the only entries were the
--- note-buffer autosave autocmds, which went away with the notes side window.

local M = {}

---@type {events: string[], scope: string, desc: string}[]
M.catalog = {}

return M
