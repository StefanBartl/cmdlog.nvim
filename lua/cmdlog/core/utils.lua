---@module 'cmdlog.core.utils'
--- Shared list helpers (reverse, dedup, and the combined processing
--- pipeline) used by every picker to turn raw history into display order.

local M = {}

--- Reverses the list (newest entries first)
--- @param entries string[]
--- @return string[]
function M.reverse_list(entries)
  local result = {}
  for i = #entries, 1, -1 do
    table.insert(result, entries[i])
  end
  return result
end

--- Removes duplicate entries, keeping first occurrence in `entries` (paired
--- with M.reverse_list in M.process_list, this keeps the *latest* occurrence
--- of the original, pre-reverse order). Delegates to lib.lua.tables.dedup_list.
--- @param entries string[]
--- @return string[]
function M.deduplicate_list(entries)
  return require("lib.lua.tables").dedup_list(entries)
end

--- Optional processing pipeline: reverse + deduplicate (if enabled)
--- @param entries string[]
--- @param opts { unique: boolean }
--- @return string[]
function M.process_list(entries, opts)
  opts = opts or {}
  local result = M.reverse_list(entries)

  if opts.unique then
    result = M.deduplicate_list(result)
  end

  return result
end

return M
