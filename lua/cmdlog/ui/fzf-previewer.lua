local M = {}

--- Returns a previewer function for fzf-lua
--- Shows file contents if the command is e.g. :edit somefile.txt
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
