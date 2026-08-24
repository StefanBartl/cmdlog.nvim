---@module 'cmdlog.ui.risky_test'
--- Output for `:Cmdlog risky test <cmd>`.
---
--- `risky_patterns` is a plain Lua-pattern list, and Lua patterns are just
--- similar enough to regexes to be written wrong with confidence. Before this
--- the only feedback was whether a line came out highlighted in a picker,
--- which cannot distinguish "the pattern is wrong" from "this command simply
--- isn't risky" -- and says nothing at all about *which* of a dozen patterns
--- fired.

local notify = require("lib.nvim.notify").create("[cmdlog]")

local M = {}

--- Report which configured patterns match `cmd`.
---@param cmd string
---@return nil
function M.report(cmd)
  cmd = type(cmd) == "string" and vim.trim(cmd) or ""
  if cmd == "" then
    notify.warn("Usage: :Cmdlog risky test <command>")
    return
  end

  local options = require("cmdlog.config").options
  local patterns = options.risky_patterns

  if type(patterns) ~= "table" or #patterns == 0 then
    notify.info(("No risky_patterns configured — nothing can match %q."):format(cmd))
    return
  end

  local matches = require("cmdlog.core.risky").matching(cmd)

  local lines = { ("Command: %s"):format(cmd) }

  if #matches == 0 then
    lines[#lines + 1] = ("No match (%d pattern(s) checked)."):format(#patterns)
  else
    lines[#lines + 1] = ("Matched %d of %d pattern(s):"):format(#matches, #patterns)
    for _, pattern in ipairs(matches) do
      lines[#lines + 1] = "  " .. pattern
    end
  end

  -- `highlight_risky` gates only the display, not the matching, so a match
  -- here does not necessarily mean the command shows up highlighted. Say so
  -- rather than letting the two look like the same thing.
  if #matches > 0 and not options.highlight_risky then
    lines[#lines + 1] = "(highlight_risky is off, so this match is not shown in pickers.)"
  end

  notify.info(table.concat(lines, "\n"))
end

return M
