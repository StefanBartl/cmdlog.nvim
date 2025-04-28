local M = {}

--- Returns a previewer function for fzf-lua.
--- The previewer attempts to show the contents of a file if the command is a simple edit command (e.g., :edit filename.txt).
--- If no file is matched or readable, no preview is provided.
--- @return fun(entry: string, _: any): string|nil
function M.command_previewer()
  return function(entry, _)
    local cmd = entry or ""

    -- Try to match simple patterns like ":edit file.txt" or ":vsp file.txt"
    local file = cmd:match("^%s*:?%s*e%d?dit%s+(%S+)$")
              or cmd:match("^%s*:?%s*vsp%s+(%S+)$")
              or cmd:match("^%s*:?%s*vs%s+(%S+)$")

    if file and vim.fn.filereadable(file) == 1 then
      return string.format("head -n 50 %s", vim.fn.shellescape(file))
    else
      -- No preview available: return nil (fzf-lua handled automatically)
      return nil
    end
  end
end

return M
