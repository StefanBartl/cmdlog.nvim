---@module 'cmdlog.bindings.autocmds'
--- Descriptive catalog of autocmds cmdlog registers. Registers nothing itself —
--- it exists so docs/BINDINGS.md (and `require("cmdlog.bindings").catalog()`)
--- have a single place to read from. The one live autocmd is created in
--- `core/tracker.lua` (only when `track_commands` is on), not here, so keep
--- this list in sync with that module by hand.

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
