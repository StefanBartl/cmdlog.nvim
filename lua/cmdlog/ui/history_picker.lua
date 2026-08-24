---@module 'cmdlog.ui.history_picker'
--- Picker showing Neovim command-line history and favorites, duplicates included.

local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")
local extra_files = require("cmdlog.core.extra_files")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- `history.delete_entry` is synchronous and returns a boolean, while the
--- picker mappings expect the async `(cmd, on_done, opts)` contract. Passing
--- it directly meant `on_done` was never called, so the picker stayed open on
--- a stale list after a successful delete. There is nothing to confirm here
--- (`:history` is in-memory, no file is rewritten), so `opts` is ignored.
---@param cmd string
---@param on_done fun(ok: boolean, err: string|nil)
---@return nil
local function delete_from_nvim_history(cmd, on_done)
  on_done(require("cmdlog.core.history").delete_entry(cmd) == true, nil)
end

--- Loads and shows a picker with favorites followed by the full (non-deduplicated)
--- Neovim `:` command-line history.
---@return nil
function M.show_history_picker()
  local favs = favorites.load()
  local raw = history.get_command_history()
  local entries = process_list(raw, { unique = false })

  local combined = vim.list_extend(vim.deepcopy(favs), entries)
  combined = vim.list_extend(combined, extra_files.get_history())

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":history (all)",
    fzf_prompt = ":history (all)> ",
    attach_mappings = require("cmdlog.ui.mappings")(
      M.show_history_picker,
      delete_from_nvim_history
    ),
  })
end

return M
