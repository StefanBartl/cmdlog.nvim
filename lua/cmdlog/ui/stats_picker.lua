---@module 'cmdlog.ui.stats_picker'
--- Picker showing commands sorted by usage frequency.

local favorites = require("cmdlog.core.favorites")
local stats = require("cmdlog.core.stats")
local picker_utils = require("cmdlog.ui.picker_utils")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim]")

local M = {}

--- Loads and shows a picker with commands sorted by usage frequency
--- (most-used first), annotated with a "used Nx, last <date>" label.
--- Only includes commands run since tracking was enabled
--- (config.options.track_commands).
--- @return nil
function M.show_stats_picker()
  local favs = favorites.load()
  local entries = stats.by_frequency()

  if #entries == 0 then
    notify.info("No usage stats recorded yet")
    return
  end

  picker_utils.open_picker(entries, favs, {
    prompt_title = ":history (by usage)",
    fzf_prompt = ":stats> ",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_stats_picker),
    label = function(entry)
      return stats.describe(entry)
    end,
  })
end

return M
