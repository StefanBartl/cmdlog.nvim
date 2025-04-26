local M = {}

-- Internal cache for history
local history_cache = nil

--- Fetch raw Neovim command-line history
--- @return string[] Raw history (oldest to newest)
function M.get_command_history()
  -- Return cached version if available
  if history_cache then
    return history_cache
  end

  local output = vim.api.nvim_exec2("history :", { output = true }).output
  local entries = {}

  for line in vim.gsplit(output, "\n") do
    local cmd = line:match("^%s*%d+%s+(.*)")
    if cmd and cmd ~= "" then
      table.insert(entries, cmd)
    end
  end

  history_cache = entries -- Cache the loaded history
  return entries
end

--- Clears the internal history cache
function M.clear_cache()
  history_cache = nil
end

--- Reverses the list (newest entries first)
--- @param entries string[]
--- @return string[]
function M.reverse_history(entries)
  local result = {}
  for i = #entries, 1, -1 do
    table.insert(result, entries[i])
  end
  return result
end

--- Removes duplicate commands, keeping latest occurrence only
--- @param entries string[]
--- @return string[]
function M.deduplicate_history(entries)
  local seen = {}
  local result = {}

  for _, cmd in ipairs(entries) do
    if not seen[cmd] then
      table.insert(result, cmd)
      seen[cmd] = true
    end
  end

  return result
end

--- Optional processing pipeline: reverse + dedup (if enabled)
--- @param entries string[]
--- @param opts { unique: boolean }
--- @return string[]
function M.process_history(entries, opts)
  opts = opts or {}
  local result = M.reverse_history(entries)

  if opts.unique then
    result = M.deduplicate_history(result)
  end

  return result
end

return M
