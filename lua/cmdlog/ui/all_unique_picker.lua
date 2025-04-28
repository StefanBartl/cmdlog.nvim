local favorites = require("cmdlog.core.favorites")
local history_mod = require("cmdlog.core.history")
local shell_mod = require("cmdlog.core.shell")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- Loads and shows a picker combining favorites and unique history entries from both Nvim and shell.
--- Ensures that favorites are always displayed first, and history entries are unique (no duplicate favorites).
--- Combined list: Favorites first, then Nvim history, then Shell history
--- Supports Telescope and fzf as picker backends.
--- @return nil
function M.show_all_unique_picker()
  local favs = favorites.load()
  local raw_hist = history_mod.get_command_history()
  local raw_shell = shell_mod.get_shell_history()
  local history = process_list(raw_hist, { unique = true })
  local shell = process_list(raw_shell, { unique = true })

  local combined = {}
  local set = {}

  for _, f in ipairs(favs) do
    table.insert(combined, f)
    set[f] = true
  end

  for _, h in ipairs(history) do
    if not set[h] then
      table.insert(combined, h)
      set[h] = true
    end
  end

  for _, s in ipairs(shell) do
    if not set[s] then
      table.insert(combined, s)
      set[s] = true
    end
  end

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":history & favorites (unique)",
    fzf_prompt = ":history & favorites (unique)> ",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_all_unique_picker),
  })
end

return M
