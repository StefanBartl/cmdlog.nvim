---@module 'cmdlog.ui.lua_picker'
--- Picker showing only Lua-mode command-line history (`:lua`, `:lua=`, `:=`).

local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim]")

local M = {}

--- Loads and shows a picker with only Lua-mode command history
--- (`:lua ...`, `:lua= ...`, `:= ...`), deduplicated.
--- @return nil
function M.show_lua_picker()
  local favs = favorites.load()
  local raw = history.get_lua_history()
  local entries = process_list(raw, { unique = true })

  if #entries == 0 then
    notify.info("No Lua-mode history found")
    return
  end

  picker_utils.open_picker(entries, favs, {
    prompt_title = ":history (Lua mode)",
    fzf_prompt = ":lua> ",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_lua_picker),
  })
end

return M
