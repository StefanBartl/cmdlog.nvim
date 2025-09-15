-- cmdlog/core/favorites.lua
-- Persistent favorites with robust normalization & migration.

local config = require("cmdlog.config")
local Path = require("plenary.path")

local M = {}

-- In-memory cache
local favorites_cache ---@type string[]|nil

--- Normalize a command for equality/storage:
--- - trim spaces
--- - strip leading UI decoration: "★ " or "* " or exactly three spaces
--- - strip exactly one leading ':'
---@param s string
---@return string
local function norm_cmd(s)
  s = tostring(s or "")
  -- trim
  s = (s:match("^%s*(.-)%s*$")) or s
  -- strip star decoration (★ or *)
  s = s:gsub("^%s*[★%*]%s+", "")
  -- strip exactly three leading spaces (our non-fav pad)
  s = s:gsub("^%s%s%s", "")
  -- strip a single leading colon
  if s:sub(1, 1) == ":" then
    s = s:sub(2)
  end
  return s
end

--- Load favorites from disk (with on-the-fly migration to normalized, deduped list).
---@return string[]
function M.load()
  if favorites_cache then
    return favorites_cache
  end

  local path = Path:new(config.options.favorites_path)

  -- Nothing yet
  if not path:exists() then
    favorites_cache = {}
    return favorites_cache
  end

  -- Read file
  local ok_read, content = pcall(function() return path:read() end)
  if not ok_read or not content or content == "" then
    favorites_cache = {}
    return favorites_cache
  end

  -- Decode JSON
  local ok_json, decoded = pcall(vim.fn.json_decode, content)
  if not ok_json or type(decoded) ~= "table" then
    favorites_cache = {}
    return favorites_cache
  end

  -- Normalize & dedupe
  local normalized ---@type string[]
  do
    normalized = {}
    local seen = {} ---@type table<string, true>
    for i = 1, #decoded do
      local n = norm_cmd(decoded[i])
      if n ~= "" and not seen[n] then
        normalized[#normalized + 1] = n
        seen[n] = true
      end
    end
  end

  -- If file contained decorated/duplicate entries, write back the clean set once
  local changed = false
  if #normalized ~= #decoded then
    changed = true
  else
    for i = 1, #normalized do
      if normalized[i] ~= decoded[i] then
        changed = true
        break
      end
    end
  end

  favorites_cache = normalized
  if changed then
    -- Persist migration
    local encoded = vim.fn.json_encode(normalized)
    -- Ensure directory exists
    path:parent():mkdir({ parents = true })
    path:write(encoded, "w")
  end

  return favorites_cache
end

--- Save given list of favorites to disk and cache.
---@param favorites string[]
function M.save(favorites)
  local path = Path:new(config.options.favorites_path)
  path:parent():mkdir({ parents = true })
  local encoded = vim.fn.json_encode(favorites)
  path:write(encoded, "w")
  favorites_cache = favorites
end

---@param cmd string
function M.toggle(cmd)
  local Norm = require("cmdlog.core.normalize")
  local target = Norm.normalize(cmd)
  local favs = M.load()
  ---@type string[]
  local new = {}
  local found = false

  for i = 1, #favs do
    local raw = favs[i]
    local entry = Norm.normalize(raw)

    if entry == target then
      found = true
    else
      new[#new + 1] = entry
    end
  end

  if not found then
    new[#new + 1] = target
  end

  -- sort & dedup
  do
    table.sort(new)
    local dedup ---@type string[]
    dedup = {}
    for i = 1, #new do
      if i == 1 or new[i] ~= new[i - 1] then
        dedup[#dedup + 1] = new[i]
      end
    end
    new = dedup
  end

  M.save(new)
end

--- Check if a command is favorited (normalized compare).
---@param cmd string
---@return boolean
function M.is_favorite(cmd)
  local target = norm_cmd(cmd)
  local favs = M.load()
  for i = 1, #favs do
    if norm_cmd(favs[i]) == target then
      return true
    end
  end
  return false
end

return M
