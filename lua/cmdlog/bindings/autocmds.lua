---@module 'cmdlog.bindings.autocmds'
--- Descriptive catalog of autocmds cmdlog registers. Registers nothing itself —
--- it exists so docs/BINDINGS.md (and `require("cmdlog.bindings").catalog()`)
--- have a single place to read from. It went empty twice, when the note-buffer
--- autosave autocmds left with the notes side window and the rest with the
--- favorite-notes feature itself (2026-08-27), which is why the tracker's own
--- autocmd was missing from it: the tracker registers in `core/tracker.lua`
--- rather than here, so emptying this list looked correct.

local M = {}

---@type {events: string[], scope: string, desc: string}[]
M.catalog = {
  {
    events = { "CmdlineLeave" },
    scope = "augroup cmdlog_tracker (cleared on every setup)",
    desc = "Record every executed ':' command into project history, usage stats and the error log. "
      .. "Registered by cmdlog.core.tracker only when `track_commands` is true; the write itself is "
      .. "deferred with vim.schedule so nothing blocks the cmdline.",
  },
}

return M
