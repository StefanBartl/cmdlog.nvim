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

return M
