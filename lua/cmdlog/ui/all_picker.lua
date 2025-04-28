local favorites = require("cmdlog.core.favorites")
local history_mod = require("cmdlog.core.history")
local shell_mod = require("cmdlog.core.shell")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- Loads and shows a picker combining all history entries and favorites.
--- Favorites are always displayed at the top.
--- Combined list: Favorites first, then Nvim history, then Shell history
--- Supports Telescope and fzf as picker backends.
--- @return nil
function M.show_all_picker()
  local favs = favorites.load()

  local raw_hist = history_mod.get_command_history()
  local raw_shell = shell_mod.get_shell_history()

  local history = process_list(raw_hist, { unique = false })
  local shell = process_list(raw_shell, { unique = false })

  local combined = {}

  for _, f in ipairs(favs) do
    table.insert(combined, f)
  end

  for _, h in ipairs(history) do
    table.insert(combined, h)
  end

  for _, s in ipairs(shell) do
    table.insert(combined, s)
  end

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":history & favorites",
    fzf_prompt = ":history & favorites> ",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_all_picker),
  })
end

return M
