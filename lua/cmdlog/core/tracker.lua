---@module 'cmdlog.core.tracker'
--- Single CmdlineLeave autocmd feeding project_history, stats and errors.
--- Kept in one place so every consumer observes exactly the same set of
--- executed ':' commands instead of each registering its own autocmd.
local config = require("cmdlog.config")
local project_history = require("cmdlog.core.project_history")
local stats = require("cmdlog.core.stats")
local errors = require("cmdlog.core.errors")
local autocmd = require("lib.nvim.bindings.autocmd")

local M = {}

local augroup = nil

--- Whether `cmd` matches any of `redact_patterns` and must therefore never
--- reach project history, stats or the error log. See DEFAULTS.lua for why
--- this exists: those stores are plaintext JSON under stdpath("data").
---@internal
---@param cmd string
---@return boolean
local function is_redacted(cmd)
  local patterns = config.options.redact_patterns
  if not patterns or patterns == false then return false end

  for _, pattern in ipairs(patterns) do
    local ok, matched = pcall(string.find, cmd, pattern)
    if ok and matched then return true end
  end

  return false
end

--- Start tracking ':' commands. Safe to call multiple times (re-creates
--- the augroup, clearing any previous autocmd).
---@return nil
function M.setup()
  if not config.options.track_commands then return end

  augroup = autocmd.group("cmdlog_tracker", true)

  autocmd.create("CmdlineLeave", function(args)
    if vim.fn.getcmdtype() ~= ":" then return end
    if args.data and args.data.abort then return end

    local cmd = vim.fn.getcmdline()
    if not cmd or cmd == "" then return end
    if is_redacted(cmd) then return end

    local errmsg_before = vim.v.errmsg

    -- Deferred: project_history.record()/stats.record() each do a
    -- synchronous JSON-encode + disk write (see core/store.lua), and
    -- project_history.record() may also resolve the Git root (cached,
    -- but still a potential subprocess spawn on a cache miss). None of
    -- that needs to finish before CmdlineLeave returns control to the
    -- editor, so it's pushed onto the next event-loop tick instead of
    -- running inline on every ':' command.
    vim.schedule(function()
      project_history.record(cmd)
      stats.record(cmd)

      if vim.v.errmsg ~= "" and vim.v.errmsg ~= errmsg_before then
        errors.record(cmd, vim.v.errmsg)
      end
    end)
  end, {
    group = augroup,
    desc = "Record every executed ':' command into history, stats and errors",
  })
end

return M
