---@module 'cmdlog.core.tags'
--- Custom tags for favorite commands. Stored separately from
--- favorites.json (config.options.favorite_tags_path) so the existing
--- flat favorites list format never has to change / migrate.
local config = require("cmdlog.config")
local store = require("cmdlog.core.store")

local M = {}

---@type table<string, string[]>|nil
local cache = nil

-- Generous headroom over any real favorites-tagging usage; a corrupt or
-- hand-edited favorite_tags.json with more entries than this is rejected
-- outright, not silently truncated.
local MAX_ENTRIES = 20000

---@internal
--- A persisted favorite_tags.json is untrusted input (SEC-33): decoding as
--- valid JSON only means the file was well-formed, not that its shape
--- matches what this module wrote -- the tag list reaches `table.concat` in
--- favorites_picker.lua, which raises on a non-string entry. Rejects the
--- whole load on the first bad entry rather than trying to salvage
--- individual ones.
---
--- Passed to `store.load_json` as its `validate` (ERR-11): a shape-invalid
--- file is well-formed JSON, so `json_decode` alone never flags it, and
--- without this hooked into the same backup path as a decode failure,
--- `save()`'s next load-modify-save would silently overwrite it with a
--- near-empty file, no backup, no trace it was ever anything else.
---@param data any
---@return boolean ok
local function is_valid(data)
  if type(data) ~= "table" then return false end
  local n = 0
  for cmd, tags in pairs(data) do
    n = n + 1
    if n > MAX_ENTRIES then return false end
    if type(cmd) ~= "string" then return false end
    if type(tags) ~= "table" then return false end
    for _, tag in ipairs(tags) do
      if type(tag) ~= "string" then return false end
    end
  end
  return true
end

---@internal
---@return table<string, string[]>
local function load()
  if cache then return cache end
  cache = store.load_json(config.options.favorite_tags_path, {}, is_valid)
  return cache
end

---@internal
---@param data table<string, string[]>
local function save(data)
  cache = data
  store.save_json(config.options.favorite_tags_path, data)
end

--- Tags for a given command (empty list if none).
---@param cmd string
---@return string[]
function M.get_tags(cmd)
  return load()[cmd] or {}
end

--- Add a tag to a command (no-op if already present).
---@param cmd string
---@param tag string
function M.add_tag(cmd, tag)
  if not cmd or cmd == "" or not tag or tag == "" then return end
  local data = load()
  local tags = data[cmd] or {}
  if not vim.tbl_contains(tags, tag) then
    table.insert(tags, tag)
    data[cmd] = tags
    save(data)
  end
end

--- Remove a tag from a command.
--- CDX: no callers and not a documented API -- no picker mapping removes a tag
--- (`<C-t>` only adds). `M.filter` is documented; `add_tag`/`get_tags` are used.
---@param cmd string
---@param tag string
function M.remove_tag(cmd, tag)
  local data = load()
  local tags = data[cmd]
  if not tags then return end
  local new_tags = {}
  for _, t in ipairs(tags) do
    if t ~= tag then table.insert(new_tags, t) end
  end
  if #new_tags == 0 then
    data[cmd] = nil
  else
    data[cmd] = new_tags
  end
  save(data)
end

--- Commands tagged with `tag`.
---@param tag string
---@return string[]
function M.filter(tag)
  local result = {}
  for cmd, tags in pairs(load()) do
    if vim.tbl_contains(tags, tag) then table.insert(result, cmd) end
  end
  return result
end

return M
