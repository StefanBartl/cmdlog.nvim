---@module 'cmdlog.ui.fzf-previewer'
--- Builds the fzf-lua previewer function for command-history entries.
---
--- fzf-lua's previewer contract is a shell command string it runs itself, so
--- the :help/:lua branches below shell out to `nvim -u NONE ... | redir` and
--- the :edit branch to `head`. Those are POSIX-only (no `head`, no reliable
--- pipe-to-redir one-liner in cmd.exe/PowerShell) -- unlike the Telescope
--- previewer (cmdlog.ui.telescope-previewer), which runs in-process and is
--- already cross-platform. Rather than emit a broken preview command on
--- Windows, this returns nil there (fzf-lua's "no preview" state).

local M = {}

--- Returns a previewer function for fzf-lua.
--- The previewer shows the contents of a file if the command is a simple edit command (e.g., :edit filename.txt).
--- It also previews `:help` and `:lua` commands.
--- If no file is matched or readable, the command is unsupported, or on Windows
--- (see module comment), no preview is provided.
--- @return fun(entry: string, _: any): string|nil
function M.command_previewer()
  local is_windows = require("lib.nvim.cross.platform.is_windows")()

  return function(entry, _)
    if is_windows then return nil end

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
      return string.format(
        "echo ':help %s' | nvim -u NONE -c 'redir! > output.txt | help %s | redir END | quit' && tail -n 50 output.txt",
        topic,
        topic
      )

    -- Handle lua command preview
    elseif cmd:match("^%s*:?%s*lua%s+(.*)$") then
      local lua_cmd = cmd:match("^%s*:?%s*lua%s+(.*)$")
      return string.format(
        "echo ':lua %s' | nvim -u NONE -c 'redir! > output.txt | lua %s | redir END | quit' && tail -n 50 output.txt",
        lua_cmd,
        lua_cmd
      )
    else
      -- No preview available: return nil (fzf-lua handled automatically)
      return nil
    end
  end
end

return M
