---@module 'cmdlog.ui.shell_picker'
--- Picker showing shell history and favorites, duplicates included.

local favorites = require("cmdlog.core.favorites")
local shell_mod = require("cmdlog.core.shell")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- Swaps argument order: `shell.delete_entry` takes `(cmd, opts, on_done)`,
--- the picker mappings call `(cmd, on_done, opts)`.
---@param cmd string
---@param on_done fun(ok: boolean, err: string|nil)
---@param opts? { skip_confirm?: boolean }
---@return nil
local function delete_from_shell_history(cmd, on_done, opts)
  shell_mod.delete_entry(cmd, opts, on_done)
end

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
    attach_mappings = require("cmdlog.ui.mappings")(M.show_shell_picker, delete_from_shell_history),
  })
end

return M
