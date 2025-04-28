local M = {}

--- Returns a previewer function for fzf-lua.
--- The previewer shows the contents of a file if the command is a simple edit command (e.g., :edit filename.txt).
--- It also previews `:help` and `:lua` commands.
--- If no file is matched or readable, or the command is unsupported, no preview is provided.
--- @return fun(entry: string, _: any): string|nil
function M.command_previewer()
  return function(entry, _)
    local cmd = entry or ""

    -- Try to match simple patterns like ":edit file.txt" or ":vsp file.txt"
    local file = cmd:match("^%s*:?%s*e%d?dit%s+(%S+)$")
              or cmd:match("^%s*:?%s*vsp%s+(%S+)$")
              or cmd:match("^%s*:?%s*vs%s+(%S+)$")

    -- Handle file preview for edit-like commands
    if file and vim.fn.filereadable(file) == 1 then
      return string.format("head -n 50 %s", vim.fn.shellescape(file))

    -- Handle help command preview
    elseif cmd:match("^%s*:?%s*help%s+(%S+)$") then
      local topic = cmd:match("^%s*:?%s*help%s+(%S+)$")
      return string.format("echo ':help %s' | nvim -u NONE -c 'redir! > output.txt | help %s | redir END | quit' && tail -n 50 output.txt", topic, topic)

    -- Handle lua command preview
    elseif cmd:match("^%s*:?%s*lua%s+(.*)$") then
      local lua_cmd = cmd:match("^%s*:?%s*lua%s+(.*)$")
      return string.format("echo ':lua %s' | nvim -u NONE -c 'redir! > output.txt | lua %s | redir END | quit' && tail -n 50 output.txt", lua_cmd, lua_cmd)

    else
      -- No preview available: return nil (fzf-lua handled automatically)
      return nil
    end
  end
end

return M
