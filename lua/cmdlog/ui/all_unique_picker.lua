local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- Loads and shows a picker combining favorites and unique history entries.
--- Ensures that favorites are always displayed first, and history entries are unique (no duplicate favorites).
--- Supports Telescope and fzf as picker backends.
--- @return nil
function M.show_all_unique_picker()
  local favs = favorites.load()
  local raw = history.get_command_history()
  local hist = process_list(raw, { unique = true })

  local set = {}
  for _, f in ipairs(favs) do
    set[f] = true
  end

  local rest = {}
  for _, h in ipairs(hist) do
    if not set[h] then
      table.insert(rest, h)
    end
  end

  local combined = vim.list_extend(vim.deepcopy(favs), rest)

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":history & favorites (unique)",
    fzf_prompt = ":history & favorites (unique)> ",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_all_unique_picker),
  })
end

return M
