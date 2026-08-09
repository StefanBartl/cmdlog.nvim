---@module 'cmdlog.core.tracker'
--- Single CmdlineLeave autocmd feeding project_history, stats and errors.
--- Kept in one place so every consumer observes exactly the same set of
--- executed ':' commands instead of each registering its own autocmd.
local config = require("cmdlog.config")
local project_history = require("cmdlog.core.project_history")
local stats = require("cmdlog.core.stats")
local errors = require("cmdlog.core.errors")

local M = {}

local augroup = nil

--- Start tracking ':' commands. Safe to call multiple times (re-creates
--- the augroup, clearing any previous autocmd).
---@return nil
function M.setup()
  if not config.options.track_commands then return end

  augroup = vim.api.nvim_create_augroup("cmdlog_tracker", { clear = true })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = augroup,
    callback = function(args)
      if vim.fn.getcmdtype() ~= ":" then return end
      if args.data and args.data.abort then return end

      local cmd = vim.fn.getcmdline()
      if not cmd or cmd == "" then return end

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
    end,
  })
end

return M
