local favorites = require("cmdlog.core.favorites")
local history = require("cmdlog.core.history")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")

local M = {}

--- Loads and shows a picker with only Lua-mode command history
--- (`:lua ...`, `:lua= ...`, `:= ...`), deduplicated.
--- @return nil
function M.show_lua_picker()
  local favs = favorites.load()
  local raw = history.get_lua_history()
  local entries = process_list(raw, { unique = true })

  if #entries == 0 then
    vim.notify("[nvim-cmdlog] No Lua-mode history found", vim.log.levels.INFO)
    return
  end

  picker_utils.open_picker(entries, favs, {
    prompt_title = ":history (Lua mode)",
    fzf_prompt = ":lua> ",
    attach_mappings = require("cmdlog.ui.mappings")(M.show_lua_picker),
  })
end

return M
