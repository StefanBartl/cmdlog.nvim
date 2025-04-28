local favorites = require("cmdlog.core.favorites")
local shell_mod = require("cmdlog.core.shell")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- Loads and shows a picker displaying shell history commands and favorites.
--- Shell history commands are shown without deduplication; duplicates are allowed.
--- Favorites are always displayed at the top.
--- Supports Telescope and fzf as picker backends.
--- @return nil
function M.show_shell_picker()
  local favs = favorites.load()
  local raw = shell_mod.get_shell_history()
  local shell_cmds = process_list(raw, { unique = false })

  local combined = vim.list_extend(vim.deepcopy(favs), shell_cmds)

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":shell & favorites (all)",
    fzf_prompt = ":shell & favorites (all)> ",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_shell_picker),
  })
end

return M
