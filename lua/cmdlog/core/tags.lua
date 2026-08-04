---@module 'cmdlog.core.tags'
--- Custom tags for favorite commands. Stored separately from
--- favorites.json (config.options.favorite_tags_path) so the existing
--- flat favorites list format never has to change / migrate.
local config = require("cmdlog.config")
local store = require("cmdlog.core.store")

local M = {}

---@type table<string, string[]>|nil
local cache = nil

---@internal
---@return table<string, string[]>
local function load()
  if cache then
    return cache
  end
  cache = store.load_json(config.options.favorite_tags_path, {})
  if type(cache) ~= "table" then
    cache = {}
  end
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
  if not cmd or cmd == "" or not tag or tag == "" then
    return
  end
  local data = load()
  local tags = data[cmd] or {}
  if not vim.tbl_contains(tags, tag) then
    table.insert(tags, tag)
    data[cmd] = tags
    save(data)
  end
end

--- Remove a tag from a command.
---@param cmd string
---@param tag string
function M.remove_tag(cmd, tag)
  local data = load()
  local tags = data[cmd]
  if not tags then
    return
  end
  local new_tags = {}
  for _, t in ipairs(tags) do
    if t ~= tag then
      table.insert(new_tags, t)
    end
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
    if vim.tbl_contains(tags, tag) then
      table.insert(result, cmd)
    end
  end
  return result
end

return M
