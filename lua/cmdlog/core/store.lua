---@module 'cmdlog.core.store'
--- Small shared JSON persistence helper for cmdlog's tracking modules
--- (project history, stats, error log).
---
--- All filesystem I/O goes through lib.nvim (fs.is_readable_file, fs.read,
--- fs.write.to_file), so this module carries no plenary.nvim dependency.
--- `fs.write.to_file` also creates missing parent directories, covering the
--- Windows/Unix mkdir edge cases itself.

local is_readable_file = require("lib.nvim.fs.is_readable_file")
local read_file = require("lib.nvim.fs.read")
local write_to_file = require("lib.nvim.fs.write.to_file")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.store]")

local M = {}

--- Load a JSON file from disk.
---
--- `err` distinguishes "nothing to load" (file missing or empty -- `default`
--- is the right, unsurprising answer) from "load failed" (file exists but
--- isn't valid JSON, or decodes fine but fails `validate`). Every consumer
--- of this module is a load-modify-save cycle: it calls this, mutates the
--- result, and hands the WHOLE table to `save_json`, which rewrites the
--- whole file -- collapsing all these cases to the same empty `default`
--- means the very next write silently replaces a corrupt file with a
--- near-empty one. On a decode failure, or a `validate` rejection, the
--- original bytes are backed up once, to `<path>.corrupt`, so that loss
--- stays recoverable even though the caller still gets `default` back this
--- session.
---
--- `validate` covers corruption `json_decode` can't see by itself: valid
--- JSON of the wrong shape (e.g. a JSON `null`/number where a caller
--- expected a list or a record) decodes cleanly and would otherwise pass
--- through as if it were legitimate data, still losing the original bytes
--- on the next save with no backup and no trace (ERR-11) -- exactly the
--- decode-failure case above, just one layer up.
---@param path string
---@param default any Value returned when the file is missing/empty/invalid
---@param validate (fun(decoded: any): boolean)|nil Optional shape check run
---  on a successfully decoded value; a `false` result is treated the same
---  as a decode failure.
---@return any data
---@return string|nil err `nil` when the file is missing or empty; set when
---  it exists but could not be decoded or decoded to the wrong shape.
function M.load_json(path, default, validate)
  local target = vim.fn.expand(path)

  if not is_readable_file(target) then return default, nil end

  local content = read_file(target)
  if not content or content == "" then return default, nil end

  local ok_json, decoded = pcall(vim.fn.json_decode, content)
  local reason = nil
  if not ok_json or decoded == nil then
    reason = "invalid JSON"
  elseif validate and not validate(decoded) then
    reason = "unexpected shape"
  end

  if reason then
    local backup_path = target .. ".corrupt"
    if not is_readable_file(backup_path) then write_to_file(backup_path, content) end
    notify.error(("'%s' is %s; original kept at '%s'"):format(target, reason, backup_path))
    return default, reason .. ": original kept at " .. backup_path
  end

  return decoded, nil
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
