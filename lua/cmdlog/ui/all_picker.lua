---@module 'cmdlog.ui.all_picker'
--- Picker showing every history entry (favorites, Neovim, and shell), duplicates included.

local favorites = require("cmdlog.core.favorites")
local history_mod = require("cmdlog.core.history")
local shell_mod = require("cmdlog.core.shell")
local extra_files = require("cmdlog.core.extra_files")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

---@internal
--- Best-effort delete across both underlying history sources: a combined-view
--- entry might originate from Neovim's `:` history, the shell history file, or
--- both. Neither call prompts/errors when `cmd` isn't found in that source.
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
  local extra = {}
  vim.list_extend(extra, extra_files.get_history())
  vim.list_extend(extra, extra_files.get_all())

  local combined = {}
  -- Tracks which non-favorite source an entry came from, for the picker's
  -- origin label (opts.label below); first occurrence wins.
  local source_of = {}

  for _, f in ipairs(favs) do
    table.insert(combined, f)
  end

  for _, h in ipairs(history) do
    if source_of[h] == nil then source_of[h] = "nvim" end
    table.insert(combined, h)
  end

  for _, s in ipairs(shell) do
    if source_of[s] == nil then source_of[s] = "shell" end
    table.insert(combined, s)
  end

  for _, e in ipairs(extra) do
    if source_of[e] == nil then source_of[e] = "extra" end
    table.insert(combined, e)
  end

  picker_utils.open_picker(combined, favs, {
    prompt_title = ":history & favorites",
    fzf_prompt = ":history & favorites> ",
    -- Distinguishes nvim/shell/extra-file origin for entries that aren't
    -- favorites (favorites already carry the ★ marker).
    label = function(cmd)
      return source_of[cmd]
    end,
    attach_mappings = require("cmdlog.ui.mappings")(M.show_all_picker, delete_from_any_history),
  })
end

return M
