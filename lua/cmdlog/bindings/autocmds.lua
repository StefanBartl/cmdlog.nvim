---@module 'cmdlog.bindings.autocmds'
--- Descriptive catalog of autocmds cmdlog registers. Registers nothing itself —
--- it exists so docs/BINDINGS.md (and `require("cmdlog.bindings").catalog()`)
--- have a single place to read from. Currently empty, and has been through two
--- rounds of it: the note-buffer autosave autocmds went with the notes side
--- window, and the rest with the favorite-notes feature itself (2026-08-27).

local M = {}

---@type {events: string[], scope: string, desc: string}[]
M.catalog = {}

return M
