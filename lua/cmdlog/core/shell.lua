---@module 'cmdlog.core.shell'
--- Detects the current shell across OSes and loads shell history safely.
--- NOTE: No UI here. Return empty strings/lists on failure; UI decides messaging.

local config = require("cmdlog.config")

local M = {}

---@alias ShellName "bash"|"zsh"|"fish"|"nu"|"ksh"|"csh"|"powershell"|"pwsh"|"cmd"
---@alias ShellVariant "posix"|"powershell"|"cmd"

---@class ShellInfo
---@field name    ShellName
---@field exe     string
---@field variant ShellVariant

-- Default history files for POSIX shells
local POSIX_HISTORY = {
  zsh  = "~/.zsh_history",
  bash = "~/.bash_history",
  fish = "~/.local/share/fish/fish_history",
  nu   = "~/.config/nushell/history.txt",
  ksh  = "~/.ksh_history",
  csh  = "~/.history",
}

---@param p string
---@return boolean
local function exists(p)
  if type(p) ~= "string" or p == "" then return false end
  local ok, st = pcall(vim.uv.fs_stat, p)
  return ok and st ~= nil
end

---@param exe string
---@return string
local function basename(exe)
  local bn = vim.fn.fnamemodify(tostring(exe or ""), ":t")
  bn = bn:gsub("%.exe$", "")
  return bn:lower()
end

--- Detect the active shell from `:set shell?`, falling back to OS env.
---@return ShellInfo|nil
local function detect_shell()
  local exe = tostring(vim.o.shell or "")
  if exe == "" then
    local sys = (vim.loop.os_uname().sysname or "")
    if sys == "Windows_NT" then
      exe = os.getenv("ComSpec") or "" -- usually cmd.exe
    else
      exe = os.getenv("SHELL") or ""
    end
  end

  local bn = basename(exe)

  -- PowerShells
  if bn == "pwsh"       then return { name = "pwsh",       exe = exe, variant = "powershell" } end
  if bn == "powershell" then return { name = "powershell", exe = exe, variant = "powershell" } end

  -- CMD
  if bn == "cmd" then return { name = "cmd", exe = exe, variant = "cmd" } end

  -- POSIX shells
  local posix = { bash=true, zsh=true, fish=true, nu=true, ksh=true, csh=true, sh=true }
  if posix[bn] then
    local n = (bn == "sh") and "bash" or bn
    return { name = n, exe = exe, variant = "posix" }
  end

  -- Heuristic defaults
  local sys = (vim.loop.os_uname().sysname or "")
  if sys == "Windows_NT" then
    return { name = "powershell", exe = "powershell.exe", variant = "powershell" }
  end
  if os.getenv("SHELL") then
    return { name = "bash", exe = os.getenv("SHELL"), variant = "posix" }
  end
  return nil
end

--- Public: canonical shell name or "".
---@return string
function M.get_shell_name()
  local info = detect_shell()
  return info and info.name or ""
end

--- Resolve history path for given shell.
---@param info ShellInfo
---@return string -- empty if not found
local function resolve_history_path(info)
  if not info then return "" end

  -- user override
  if config and config.options and config.options.shell_history_path ~= "default" then
    local p = vim.fn.expand(tostring(config.options.shell_history_path))
    return exists(p) and p or ""
  end

  if info.variant == "powershell" then
    -- PSReadLine:
    --  - pwsh 7+:   %APPDATA%\Microsoft\PowerShell\PSReadLine\ConsoleHost_history.txt
    --  - PS 5.1:    %APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
    local app = vim.fn.expand("$APPDATA")
    if app and app ~= "" then
      local p7  = app .. "/Microsoft/PowerShell/PSReadLine/ConsoleHost_history.txt"
      local p51 = app .. "/Microsoft/Windows/PowerShell/PSReadLine/ConsoleHost_history.txt"
      if exists(p7)  then return p7 end
      if exists(p51) then return p51 end
    end
    return ""
  elseif info.variant == "cmd" then
    -- Optional (Clink)
    local p = vim.fn.expand("$LOCALAPPDATA") .. "/clink/clink_history"
    return exists(p) and p or ""
  else
    local p = POSIX_HISTORY[info.name]
    if not p then return "" end
    p = vim.fn.expand(p)
    return exists(p) and p or ""
  end
end

--- Public: path to history or "".
---@return string
function M.get_shell_history_path()
  local info = detect_shell()
  return resolve_history_path(info)
end

--- Parse history file lines into commands.
---@param data string[]
---@param shell ShellName
---@return string[]
local function parse_history(data, shell)
  local out = {}
  if type(data) ~= "table" or #data == 0 then return out end
  shell = shell or "bash"

  for i = 1, #data do
    local line = tostring(data[i] or "")
    repeat
      if shell == "zsh" then
        local cmd = line:match(";%s*(.*)")
        if cmd and cmd ~= "" then out[#out+1] = cmd end
        break
      end

      if shell == "bash" or shell == "ksh" or shell == "csh" then
        if line ~= "" and not line:match("^#%d+") then out[#out+1] = line end
        break
      end

      if shell == "fish" then
        -- fish history YAML-ish:  - cmd: echo \"hi\"
        local cmd = line:match("^%s*%-+%s*cmd:%s*(.*)")
        if cmd and cmd ~= "" then
          local ok, decoded = pcall(vim.fn.json_decode, '"' .. cmd .. '"')
          out[#out+1] = ok and decoded or cmd
        end
        break
      end

      if shell == "nu" then
        if line ~= "" then out[#out+1] = line end
        break
      end

      if shell == "powershell" or shell == "pwsh" then
        -- PSReadLine is plain text, one command per line
        if line ~= "" then out[#out+1] = line end
        break
      end

      if shell == "cmd" then
        -- Clink history is plain text lines
        if line ~= "" then out[#out+1] = line end
        break
      end

      break
    until true
  end

  return out
end

--- Public: load shell history (oldest→newest). Returns {} if not available.
---@return string[]
function M.get_shell_history()
  local info = detect_shell()
  if not info then return {} end
  local path = resolve_history_path(info)
  if path == "" then return {} end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or type(lines) ~= "table" then return {} end

  return parse_history(lines, info.name)
end

--- Public: expose detected shell info (nil if unknown).
---@return ShellInfo|nil
function M.get_shell_info()
  return detect_shell()
end

return M
