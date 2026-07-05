local M = {}

--- Fetch raw Neovim command-line history
--- @return string[] Raw history (oldest to newest)
function M.get_command_history()
  local output = vim.api.nvim_exec2("history :", { output = true }).output
  local entries = {}

  for line in vim.gsplit(output, "\n") do
    local cmd = line:match("^%s*%d+%s+(.*)")
    if cmd and cmd ~= "" then
      table.insert(entries, cmd)
    end
  end

  return entries
end

--- Deletes every entry matching `cmd` from Neovim's `:` command-line history.
--- Uses `histdel()`, which affects only the in-memory (and, on exit, shada-persisted)
--- history — nothing on disk is touched directly.
---@param cmd string
---@return boolean ok
function M.delete_entry(cmd)
  local pattern = "^" .. vim.fn.escape(cmd, "\\/.*$^~[]") .. "$"
  local ok, result = pcall(vim.fn.histdel, ":", pattern)
  return ok and result == 1
end

return M
