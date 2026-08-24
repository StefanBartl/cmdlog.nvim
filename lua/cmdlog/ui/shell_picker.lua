---@module 'cmdlog.ui.shell_picker'
--- Picker showing shell history and favorites, duplicates included.

local favorites = require("cmdlog.core.favorites")
local shell_mod = require("cmdlog.core.shell")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- `shell.delete_entry` takes `(cmd, opts, on_done)`, but the picker mappings
--- call `(cmd, on_done, opts)`. Passing it directly put the callback in the
--- `opts` slot and left `on_done` nil, so <C-x> in this picker raised
--- "attempt to call local 'on_done' (a nil value)" instead of deleting
--- anything. This adapter is the swap.
---@param cmd string
---@param on_done fun(ok: boolean, err: string|nil)
---@param opts? { skip_confirm?: boolean }
---@return nil
local function delete_from_shell_history(cmd, on_done, opts)
  require("cmdlog.core.shell").delete_entry(cmd, opts, on_done)
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
