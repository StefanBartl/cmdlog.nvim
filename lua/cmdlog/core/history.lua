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

--- Fetch Neovim command-line history entries that are Lua-mode commands:
--- `:lua ...`, `:lua= ...` and `:= ...` (the expression register / `:lua=`
--- shorthand). Plain `:lua` invocations already live in the regular `:`
--- history; this is a filtered view for quickly finding just those.
--- @return string[] Lua-mode entries (oldest to newest)
function M.get_lua_history()
  local entries = {}
  for _, cmd in ipairs(M.get_command_history()) do
    if cmd:match("^lua!?%s") or cmd:match("^lua!?=") or cmd:match("^=") then
      table.insert(entries, cmd)
    end
  end
  return entries
end

return M
