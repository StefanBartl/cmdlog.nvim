---@module 'cmdlog.ui.shell_unique_picker'
--- Picker showing deduplicated shell history and favorites.

local favorites = require("cmdlog.core.favorites")
local shell_mod = require("cmdlog.core.shell")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")
local cycle = require("cmdlog.ui.cycle")

local M = {}

--- Loads and shows a picker displaying unique shell history commands combined with favorites.
--- Shell history commands are deduplicated to show each command only once.
--- Favorites are always displayed at the top.
--- Supports Telescope and fzf as picker backends.
--- @param initial_text? string Prompt text to pre-fill, used by `mappings.cycle_source`
--- @return nil
function M.show_shell_unique_picker(initial_text)
  local favs = favorites.load()
  local raw = shell_mod.get_shell_history()
  local shell_cmds = process_list(raw, { unique = true })

  local combined = vim.list_extend(vim.deepcopy(favs), shell_cmds)

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":shell & favorites (unique)",
    fzf_prompt = ":shell & favorites (unique)> ",
    default_text = initial_text,
    attach_mappings = function(prompt_bufnr, map)
      cycle.attach(prompt_bufnr, map, "shell")
      return require("cmdlog.ui.mappings")(
        M.show_shell_unique_picker,
        shell_mod.delete_entry
      )(prompt_bufnr, map)
    end,
  })
end

return M
