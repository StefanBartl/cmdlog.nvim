---@module 'cmdlog.core.store'
--- Small shared JSON persistence helper for cmdlog's tracking modules
--- (project history, stats, error log).
---
--- All filesystem I/O goes through lib.nvim (fs.is_readable_file, fs.read,
--- fs.write.to_file) instead of plenary.path, so this module carries no
--- plenary.nvim dependency — the same treatment core/favorites.lua got.
--- lib.nvim.fs.write.to_file also creates missing parent directories and
--- already covers the Windows/Unix mkdir edge cases this module used to
--- reimplement with a plenary fallback.

local is_readable_file = require("lib.nvim.fs.is_readable_file")
local read_file = require("lib.nvim.fs.read")
local write_to_file = require("lib.nvim.fs.write.to_file")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.store]")

local M = {}

--- Load a JSON file from disk.
---@param path string
---@param default any Value returned when the file is missing/empty/invalid
---@return any
function M.load_json(path, default)
  local target = vim.fn.expand(path)

  if not is_readable_file(target) then return default end

  local content = read_file(target)
  if not content or content == "" then return default end

  local ok_json, decoded = pcall(vim.fn.json_decode, content)
  if not ok_json or decoded == nil then return default end

  return decoded
end

--- Save a value as JSON to disk, creating parent directories as needed.
---@param path string
---@param data any
---@return boolean success
function M.save_json(path, data)
  local encoded = vim.fn.json_encode(data)
  local target = vim.fn.expand(path)

  local ok, err = write_to_file(target, encoded)
  if not ok then
    notify.error(("Failed to write '%s': %s"):format(tostring(path), tostring(err)))
    return false
  end

  return true
end

return M
