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

--- Removes duplicate entries, keeping latest occurrence only
--- @param entries string[]
--- @return string[]
function M.deduplicate_list(entries)
  local seen = {}
  local result = {}

  for _, entry in ipairs(entries) do
    if not seen[entry] then
      table.insert(result, entry)
      seen[entry] = true
    end
  end

  return result
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
