---@module 'cmdlog.ui.history_unique_picker'
--- Picker showing deduplicated Neovim command-line history and favorites.

local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")
local extra_files = require("cmdlog.core.extra_files")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")
local cycle = require("cmdlog.ui.cycle")

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

--- Loads and shows a picker displaying unique command history entries.
--- Commands are deduplicated to show each command only once.
--- Favorites are highlighted but not prioritized at the top.
--- Supports Telescope and fzf as picker backends.
--- @param initial_text? string Prompt text to pre-fill, used by `mappings.cycle_source`
--- @return nil
function M.show_history_unique_picker(initial_text)
  local favs = favorites.load()
  local raw = history.get_command_history()
  local entries = process_list(raw, { unique = true })

  local combined = vim.list_extend(vim.deepcopy(favs), entries)
  combined = vim.list_extend(combined, extra_files.get_history())

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":history (unique)",
    fzf_prompt = ":history (unique)> ",
    default_text = initial_text,
    attach_mappings = function(prompt_bufnr, map)
      cycle.attach(prompt_bufnr, map, "nvim")
      return require("cmdlog.ui.mappings")(M.show_history_unique_picker, delete_from_nvim_history)(
        prompt_bufnr,
        map
      )
    end,
  })
end

return M
