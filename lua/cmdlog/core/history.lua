local M = {}

--- Fetch raw Neovim command-line history
--- @return string[] Raw history (oldest to newest)
function M.get_command_history()
  local entries = {}
  local i = 1

  while true do
    local entry = vim.fn.histget(":", i)
    if not entry or entry == "" then break end
    table.insert(entries, entry)
    i = i + 1
  end

  return entries
end

--- Clean and reverse history (remove duplicates, newest first)
--- @param entries string[] Raw history
--- @return string[] Processed history
function M.process_history(entries)
  local seen = {}
  local result = {}

  -- iterate backwards to preserve most recent entry if duplicate
  for i = #entries, 1, -1 do
    local cmd = entries[i]
    if not seen[cmd] then
      table.insert(result, cmd)
      seen[cmd] = true
    end
  end

  return result
end

return M
