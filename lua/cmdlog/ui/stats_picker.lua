local favorites = require("cmdlog.core.favorites")
local stats = require("cmdlog.core.stats")
local picker_utils = require("cmdlog.ui.picker_utils")

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
    vim.notify("[nvim-cmdlog] No usage stats recorded yet", vim.log.levels.INFO)
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
