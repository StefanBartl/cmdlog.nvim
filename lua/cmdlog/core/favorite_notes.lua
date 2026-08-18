---@module 'cmdlog.core.favorite_notes'
--- Short free-text notes attached to favorites -- one line of context added
--- via `vim.ui.input()`, not an editable buffer. Stored separately from
--- favorites.json (config.options.favorite_notes_path) so the flat
--- favorites list format never has to migrate, and separately from
--- favorite_tags_path so neither feature's storage shape constrains the
--- other -- same treatment `core/tags.lua` got.
local config = require("cmdlog.config")
local store = require("cmdlog.core.store")

local M = {}

---@type table<string, string>|nil
local cache = nil

---@internal
---@return table<string, string>
local function load()
  if cache then return cache end
  cache = store.load_json(config.options.favorite_notes_path, {})
  if type(cache) ~= "table" then cache = {} end
  return cache
end

---@internal
---@param data table<string, string>
local function save(data)
  cache = data
  store.save_json(config.options.favorite_notes_path, data)
end

--- The note for a given command, or `nil` if it has none.
---@param cmd string
---@return string|nil
function M.get_note(cmd)
  local note = load()[cmd]
  if note and note ~= "" then return note end
  return nil
end

--- Set (add or overwrite) the note for a command. There is no separate
--- delete entry point -- passing `nil`/`""` removes it, which is what
--- `ui/mappings.lua`'s `mappings.note` does when you clear the input and
--- confirm.
---@param cmd string
---@param note string|nil
function M.set_note(cmd, note)
  if not cmd or cmd == "" then return end
  local data = load()

  if note == nil or note == "" then
    if data[cmd] == nil then return end
    data[cmd] = nil
  else
    data[cmd] = note
  end

  save(data)
end

return M
