---@module 'cmdlog.shell'
--- Utilities to detect the user's interactive shell and read its history.
--- Supports POSIX shells (bash, zsh, fish, ksh, csh), nushell (nu) and PowerShell
--- (Windows PowerShell and PowerShell Core / pwsh) on Windows and Unix-like systems.
--- Detection strategy:
---  - Prefer vim.env.SHELL if set (POSIX style path like /bin/zsh).
---  - If SHELL is unset (common on Windows), probe known history-file locations and
---    pick the first that exists.
---  - For PowerShell, respect platform differences:
---      * Windows: use $env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
---      * Unix-like: use XDG path ~/.local/share/powershell/PSReadLine/ConsoleHost_history.txt
--- Notes:
---  - This module only *reads* history files; it does not interact with running shells.
---  - The PSReadLine history file format is plain text (one command per line).
---  - The module expands ~ and environment variables before checking existence.
---  - All user-facing notifications are in German in calling code; this module logs
---    only warnings where parsing fails.
local M = {}

--AUDIT: Modularisieren, Annotationen klären

--- Map of supported shells to a canonical ID. Values are not final paths but keys
--- that are later expanded depending on platform and config.
---@type table<string,string>
local supported_shells = {
  zsh = "zsh",
  bash = "bash",
  fish = "fish",
  nu = "nu",
  ksh = "ksh",
  csh = "csh",
  powershell = "powershell", -- covers both Windows PowerShell and pwsh when detected
  pwsh = "powershell",
}

--- Default history locations (template strings). These may contain ~ or require
--- combining environment variables (APPDATA) on Windows.
---@type table<string,string>
local default_history_templates = {
  zsh = "~/.zsh_history",
  bash = "~/.bash_history",
  fish = "~/.local/share/fish/fish_history",
  nu = "~/.config/nushell/history.txt",
  ksh = "~/.ksh_history",
  csh = "~/.history",
  -- PowerShell: Windows uses %APPDATA%/... ; Unix-like uses XDG location
  powershell_windows = "%APPDATA%\\Microsoft\\Windows\\PowerShell\\PSReadLine\\ConsoleHost_history.txt",
  powershell_unix = "~/.local/share/powershell/PSReadLine/ConsoleHost_history.txt",
}

--- Utility: expand a path template into an absolute path, handling:
---  - leading ~ -> HOME
---  - %VARNAME% -> environment variable (Windows style)
---  - $VARNAME -> env var (POSIX style)
---  - returns expanded string
---@param tpl string
---@return string
local function expand_path_template(tpl)
  if not tpl or tpl == "" then
    return ""
  end

  -- Expand ~
  local expanded = tpl
  if expanded:sub(1, 2) == "~/" or expanded == "~" then
    local home = vim.env.HOME or vim.env.USERPROFILE or ""
    expanded = home .. expanded:sub(2)
  end

  -- Expand POSIX $VAR patterns using vim.env
  expanded = expanded:gsub("%$([%w_]+)", function(k)
    return vim.env[k] or ""
  end)

  -- Expand Windows style %VAR% occurrences
  expanded = expanded:gsub("%%([%w_]+)%%", function(k)
    return vim.env[k] or ""
  end)

  -- normalize forward slashes (vim.readfile and fs checks accept / on Windows)
  expanded = expanded:gsub("\\", "/")

  return expanded
end

--- Utility: check whether a file exists (string path). Uses vim.loop.fs_stat for robust cross-platform check.
---@param path string
---@return boolean
local function file_exists(path)
  if not path or path == "" then
    return false
  end
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil and stat.type == "file"
end

--- Returns the detected shell name (one of supported_shells keys) or empty string if none.
--- Detection order:
---  1. If vim.env.SHELL present -> use its basename if supported.
---  2. If SHELL absent (Windows), probe likely history files (PowerShell, cmd alternatives).
---  3. If still unknown, return "" and the caller will handle the warning.
---@return string
function M.get_shell_name()
  -- 1) Prefer SHELL environment variable (POSIX)
  local shell_env = vim.env.SHELL or ""
  if shell_env ~= "" then
    -- Get basename (e.g., /bin/zsh -> zsh)
    local basename = shell_env:match("([^/\\]+)$") or shell_env
    basename = basename:lower()
    if supported_shells[basename] then
      return supported_shells[basename]
    end
  end

  -- 2) If SHELL missing or not supported, try to detect by probing history file locations.
  --    This helps on Windows where SHELL is commonly unset.
  -- Build candidate list in preferred order (PowerShell first on Windows).
  local is_windows = package.config:sub(1, 1) == "\\"

  local candidates = {}
  if is_windows then
    -- Prefer PowerShell on Windows
    table.insert(candidates, "powershell")
    table.insert(candidates, "pwsh")
    -- also consider bash/zsh via WSL or Git Bash if their history exists under HOME
    table.insert(candidates, "bash")
    table.insert(candidates, "zsh")
    table.insert(candidates, "fish")
    table.insert(candidates, "nu")
    table.insert(candidates, "ksh")
    table.insert(candidates, "csh")
  else
    -- Unix-like: probe common shells
    table.insert(candidates, "zsh")
    table.insert(candidates, "bash")
    table.insert(candidates, "fish")
    table.insert(candidates, "nu")
    table.insert(candidates, "ksh")
    table.insert(candidates, "csh")
    -- also check PowerShell Core location on Unix-like systems
    table.insert(candidates, "pwsh")
  end

  for _, cand in ipairs(candidates) do
    local path_tpl
    if cand == "powershell" or cand == "pwsh" then
      if is_windows then
        path_tpl = default_history_templates.powershell_windows
      else
        path_tpl = default_history_templates.powershell_unix
      end
    else
      path_tpl = default_history_templates[cand]
    end
    local expanded = expand_path_template(path_tpl)
    if file_exists(expanded) then
      -- normalized key
      if cand == "pwsh" then
        return "powershell"
      end
      return cand
    end
  end

  -- 3) Nothing found
  return ""
end

--- Returns the full path to the detected shell's history file, or "" on failure.
--- If config.options.shell_history_path is set and not "default", that value is respected
--- (expanded). Otherwise the default templates are used and expanded.
---@return string
function M.get_shell_history_path()
  -- Allow override from plugin config (if present)
  local cfg = require("cmdlog.config")
  local override = cfg and cfg.options and cfg.options.shell_history_path or "default"
  if override and type(override) == "string" and override ~= "default" and override ~= "" then
    local expanded = expand_path_template(override)
    if file_exists(expanded) then
      return expanded
    else
      -- Configured path missing -> warn and fall through to detection
      vim.notify("[nvim-cmdlog]: Konfigurierter Shell-History-Pfad nicht gefunden: '" .. tostring(expanded) .. "'.", vim.log.levels.WARN)
      -- continue to detection below
    end
  end

  local shell = M.get_shell_name()
  if shell == "" then
    vim.notify("[nvim-cmdlog]: Konnte Shell nicht erkennen. Unterstützte Shells: " .. table.concat(vim.tbl_keys(supported_shells), ", "), vim.log.levels.WARN)
    return ""
  end

  local is_windows = package.config:sub(1, 1) == "\\"
  local tpl
  if shell == "powershell" then
    if is_windows then
      tpl = default_history_templates.powershell_windows
    else
      tpl = default_history_templates.powershell_unix
    end
  else
    tpl = default_history_templates[shell]
  end

  if not tpl then
    vim.notify("[nvim-cmdlog]: Keine Standard-History-Vorlage für Shell '" .. shell .. "' definiert.", vim.log.levels.WARN)
    return ""
  end

  local expanded = expand_path_template(tpl)
  if not file_exists(expanded) then
    vim.notify("[nvim-cmdlog]: Standard-Shell-History nicht gefunden unter '" .. tostring(expanded) .. "'.", vim.log.levels.WARN)
    return ""
  end

  return expanded
end

--- Returns a list (array) of commands read from the shell history file.
--- The parsing is tailored for each supported shell format.
--- @return string[] history lines (commands)
function M.get_shell_history()
  ---@type string[]
  local history = {}

  local path = M.get_shell_history_path()
  if path == "" then
    return history
  end

  -- readfile returns a table of lines
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines or vim.tbl_isempty(lines) then
    return history
  end

  local shell = M.get_shell_name()
  if shell == "" then
    return history
  end

  -- Parse according to shell type
  if shell == "zsh" then
    -- zsh extended history format: : 1609459200:0;command
    for _, line in ipairs(lines) do
      local cmd = line:match(";%s*(.*)")
      if cmd and cmd ~= "" then
        table.insert(history, cmd)
      end
    end

  elseif shell == "bash" or shell == "ksh" or shell == "csh" then
    -- bash plain lines or with timestamps commented (#1609459200)
    for _, line in ipairs(lines) do
      if line ~= "" and not line:match("^#%d+") then
        table.insert(history, line)
      end
    end

  elseif shell == "fish" then
    -- fish YAML-ish entries: - cmd: '...'
    for _, line in ipairs(lines) do
      local cmd = line:match("^%s*%- cmd:%s*(.*)")
      if cmd and cmd ~= "" then
        -- unescape using JSON decode trick to honor escape sequences
        local okdec, dec = pcall(vim.fn.json_decode, '"' .. cmd .. '"')
        if okdec and dec then
          table.insert(history, dec)
        else
          table.insert(history, cmd)
        end
      end
    end

  elseif shell == "nu" then
    -- nushell history is typically plain lines
    for _, line in ipairs(lines) do
      if line ~= "" then
        table.insert(history, line)
      end
    end

  elseif shell == "powershell" then
    -- PSReadLine history file is plain one-command-per-line
    for _, line in ipairs(lines) do
      if line and line ~= "" then
        table.insert(history, line)
      end
    end

  else
    -- Unknown shell fallback: attempt to return non-empty lines
    for _, line in ipairs(lines) do
      if line and line ~= "" then
        table.insert(history, line)
      end
    end
  end

  return history
end

return M
