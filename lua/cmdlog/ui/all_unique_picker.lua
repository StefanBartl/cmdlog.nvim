---@module 'cmdlog.ui.all_unique_picker'
--- Picker showing every history entry (favorites, Neovim, and shell), deduplicated.

local favorites = require("cmdlog.core.favorites")
local history_mod = require("cmdlog.core.history")
local shell_mod = require("cmdlog.core.shell")
local extra_files = require("cmdlog.core.extra_files")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

---@internal
--- Best-effort delete across both underlying history sources; see all_picker.lua.
---@param cmd string
---@param on_done fun(ok: boolean, err: string|nil)
local function delete_from_any_history(cmd, on_done)
  local nvim_ok = history_mod.delete_entry(cmd)
  shell_mod.delete_entry(cmd, nil, function(shell_ok, shell_err)
    if nvim_ok or shell_ok then
      on_done(true)
    else
      on_done(false, shell_err)
    end
  end)
end

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
  local extra = {}
  vim.list_extend(extra, extra_files.get_history())
  vim.list_extend(extra, extra_files.get_all())

  local combined = {}
  local set = {}
  -- Tracks which non-favorite source an entry came from, for the picker's
  -- origin label (opts.label below); first occurrence wins.
  local source_of = {}

  for _, f in ipairs(favs) do
    table.insert(combined, f)
    set[f] = true
  end

  for _, h in ipairs(history) do
    if not set[h] then
      table.insert(combined, h)
      set[h] = true
      source_of[h] = "nvim"
    end
  end

  for _, s in ipairs(shell) do
    if not set[s] then
      table.insert(combined, s)
      set[s] = true
      source_of[s] = "shell"
    end
  end

  for _, e in ipairs(extra) do
    if not set[e] then
      table.insert(combined, e)
      set[e] = true
      source_of[e] = "extra"
    end
  end

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":history & favorites (unique)",
    fzf_prompt = ":history & favorites (unique)> ",
    -- Distinguishes nvim/shell/extra-file origin for entries that aren't
    -- favorites (favorites already carry the ★ marker).
    label = function(cmd)
      return source_of[cmd]
    end,
    attach_mappings = require("cmdlog.ui.mappings")(
      M.show_all_unique_picker,
      delete_from_any_history
    ),
  })
end

return M
