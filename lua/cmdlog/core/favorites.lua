local config = require("cmdlog.config")
local Path = require("plenary.path")

local M = {}

--- Load favorites from disk
--- @return string[] favorites or empty table
function M.load()
  local path = Path:new(config.options.favorites_path)

  if not path:exists() then return {} end

  local ok, content = pcall(function() return path:read() end)
  if not ok or not content or content == "" then return {} end

  local ok_json, decoded = pcall(vim.fn.json_decode, content)
  if not ok_json or type(decoded) ~= "table" then return {} end

  return decoded
end

--- Save given list of favorites to disk
--- @param favorites string[]
function M.save(favorites)
  local path = Path:new(config.options.favorites_path)
  path:parent():mkdir({ parents = true }) -- ensure directory exists

  local encoded = vim.fn.json_encode(favorites)
  path:write(encoded, "w")
end

--- Toggle a command in favorites
--- @param cmd string
function M.toggle(cmd)
  local favs = M.load()
  local new = {}

  local found = false
  for _, entry in ipairs(favs) do
    if entry == cmd then
      found = true
    else
      table.insert(new, entry)
    end
  end

  if not found then table.insert(new, cmd) end

  M.save(new)
end

--- Check if a command is a favorite
--- @param cmd string
--- @return boolean
function M.is_favorite(cmd)
  local favs = M.load()
  for _, entry in ipairs(favs) do
    if entry == cmd then return true end
  end
  return false
end

return M
