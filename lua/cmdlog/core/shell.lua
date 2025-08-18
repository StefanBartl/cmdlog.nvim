---@module 'cmdlog.core.shell'
--- Cross-platform shell detection and history path resolution, with Windows/PowerShell support.
--- - Detects shell via $SHELL (POSIX), 'vim.o.shell', and $ComSpec (Windows).
--- - Supports zsh, bash, fish, nu, ksh, csh, pwsh (PowerShell 7+), powershell (Windows PowerShell).
--- - Resolves PSReadLine history locations on Windows/macOS/Linux.
--- - Reads PowerShell history with BOM detection (UTF-16LE/BE) and UTF-8 fallback.
--- - Keeps backwards-compatible override via config.options.shell_history_path.

local config = require("cmdlog.config")

---@alias ShellName "zsh"|"bash"|"fish"|"nu"|"ksh"|"csh"|"pwsh"|"powershell"|"cmd"
---@class CmdlogShell
local M = {}

-- Default history file globs for POSIX-like shells (resolved via ~ expansion).
-- PowerShell and cmd are handled in dedicated code paths below.
local supported_shells = {
	zsh = "~/.zsh_history",
	bash = "~/.bash_history",
	fish = "~/.local/share/fish/fish_history",
	nu = "~/.config/nushell/history.txt",
	ksh = "~/.ksh_history",
	csh = "~/.history",
	pwsh = "__DYNAMIC__",      -- PowerShell 7+ (Core)
	powershell = "__DYNAMIC__", -- Windows PowerShell 5.1
	cmd = "__DYNAMIC__",       -- Not guaranteed; optional via Clink
}

--- Trim helper (remove leading/trailing whitespace)
---@param s string
---@return string
local function trim(s)
	return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Return current OS name in lowercase (e.g., "windows_nt", "linux", "darwin").
---@return string
local function os_name()
	local uname = vim.uv.os_uname()
	return (uname and uname.sysname or ""):lower()
end

--- Detect active shell name cross-platform.
--- On Windows, prefer vim.o.shell, then pwsh/powershell/cmd fallbacks.
--- On POSIX, $SHELL or vim.o.shell are used.
---@return ShellName|"" shell
function M.get_shell_name()
	local sys = os_name()
	local shell_env = vim.env.SHELL or ""
	local opt_shell = vim.o.shell or ""
	local comspec = vim.env.ComSpec or ""

	local function basename(p)
		return (p or ""):gsub("\\", "/"):match("([^/]+)$") or ""
	end

	if sys:find("windows") then
		-- Check Neovim's shell option first (user-configured)
		local cand = { opt_shell, "pwsh.exe", "powershell.exe", "bash.exe", comspec }
		for _, s in ipairs(cand) do
			if type(s) == "string" and #s > 0 then
				local b = basename(s):lower()
				if b:find("pwsh") then
					return "pwsh"
				end
				if b:find("powershell") then
					return "powershell"
				end
				if b:find("bash") then
					return "bash"
				end
				if b == "cmd.exe" or b == "cmd" then
					return "cmd"
				end
			end
		end
		-- Last resort: treat as cmd
		return "cmd"
	else
		-- POSIX: favor $SHELL if available, else vim.o.shell, with basename normalization.
		local s = (#shell_env > 0) and shell_env or opt_shell
		local b = basename(s):lower()
		if supported_shells[b] ~= nil then
			return b -- known shell
		end
		-- Heuristics: map sh->bash for history parsing, if present.
		if b == "sh" then
			return "bash"
		end
		-- Unknown: warn once and return ""
		vim.notify(
			"[nvim-cmdlog]: Unsupported shell '"
			.. (b or s)
			.. "'. Supported shells: "
			.. table.concat(vim.tbl_keys(supported_shells), ", "),
			vim.log.levels.WARN
		)
		return ""
	end
end

--- Resolve PowerShell (pwsh / Windows PowerShell) PSReadLine history path for current OS.
--- Tries multiple canonical locations and returns the first existing file.
---@param shell ShellName
---@return string path_or_empty
local function resolve_powershell_history(shell)
	local sys = os_name()

	-- Candidate list helper: return the first existing file
	local function first_existing(paths)
		for _, p in ipairs(paths) do
			local expanded = vim.fn.expand(p)
			if type(expanded) == "string" and #expanded > 0 and vim.uv.fs_stat(expanded) then
				return expanded
			end
		end
		return ""
	end

	if sys:find("windows") then
		-- Windows PowerShell (5.1): %APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt
		-- PowerShell 7+:          %APPDATA%\Microsoft\PowerShell\PSReadLine\ConsoleHost_history.txt
		local appdata = vim.env.APPDATA or ""
		local localapp = vim.env.LOCALAPPDATA or ""
		local cands = {}
		if #appdata > 0 then
			table.insert(cands, appdata .. "\\Microsoft\\PowerShell\\PSReadLine\\ConsoleHost_history.txt")
			table.insert(cands, appdata .. "\\Microsoft\\Windows\\PowerShell\\PSReadLine\\ConsoleHost_history.txt")
		end
		if #localapp > 0 then
			-- Some setups store it under Local
			table.insert(cands, localapp .. "\\Microsoft\\PowerShell\\PSReadLine\\ConsoleHost_history.txt")
			table.insert(cands, localapp .. "\\Microsoft\\Windows\\PowerShell\\PSReadLine\\ConsoleHost_history.txt")
		end
		return first_existing(cands)
	elseif sys:find("darwin") then
		-- macOS (pwsh installed): ~/Library/Application Support/powershell/PSReadLine/ConsoleHost_history.txt
		return first_existing({
			"~/Library/Application Support/powershell/PSReadLine/ConsoleHost_history.txt",
		})
	else
		-- Linux / BSD: ~/.local/share/powershell/PSReadLine/ConsoleHost_history.txt
		return first_existing({
			"~/.local/share/powershell/PSReadLine/ConsoleHost_history.txt",
		})
	end
end

--- Optionally resolve cmd.exe history via Clink if present. Otherwise empty.
--- Known Clink paths (not guaranteed): %LOCALAPPDATA%\clink\history or %APPDATA%\clink\history
---@return string path_or_empty
local function resolve_cmd_history()
	local sys = os_name()
	if not sys:find("windows") then
		return ""
	end
	local cands = {}
	if vim.env.LOCALAPPDATA then
		table.insert(cands, vim.env.LOCALAPPDATA .. "\\clink\\history")
	end
	if vim.env.APPDATA then
		table.insert(cands, vim.env.APPDATA .. "\\clink\\history")
	end
	for _, p in ipairs(cands) do
		if vim.uv.fs_stat(p) then
			return p
		end
	end
	return ""
end

--- Read a whole text file with BOM detection (UTF-8/UTF-16LE/BE), return as lines.
---@param file string
---@return string[] lines
local function read_text_file_lines(file)
	local stat = vim.uv.fs_stat(file)
	if not stat or stat.type ~= "file" then
		return {}
	end
	local fd, open_err = vim.uv.fs_open(file, "r", 438)
	if not fd then
		vim.notify("[nvim-cmdlog]: Failed to open history file: " .. tostring(open_err), vim.log.levels.WARN)
		return {}
	end
	local data = vim.uv.fs_read(fd, stat.size, 0) or ""
	vim.uv.fs_close(fd)

	if data == "" then
		return {}
	end

	-- Detect BOMs
	local b1, b2, b3 = data:byte(1), data:byte(2), data:byte(3)
	local text = data
	if b1 == 0xEF and b2 == 0xBB and b3 == 0xBF then
		text = data:sub(4) -- UTF-8 BOM
	elseif b1 == 0xFF and b2 == 0xFE then
		-- UTF-16LE -> UTF-8
		local payload = data:sub(3)
		local ok, conv = pcall(vim.fn.iconv, payload, "ucs-2le", "utf-8")
		text = ok and (conv or "") or ""
	elseif b1 == 0xFE and b2 == 0xFF then
		-- UTF-16BE -> UTF-8
		local payload = data:sub(3)
		local ok, conv = pcall(vim.fn.iconv, payload, "ucs-2be", "utf-8")
		text = ok and (conv or "") or ""
	else
		-- Assume UTF-8 already
		text = data
	end

	-- Normalize line endings and split
	text = text:gsub("\r\n", "\n")
	local lines = {}
	for line in (text .. "\n"):gmatch("([^\n]*)\n") do
		table.insert(lines, line)
	end
	return lines
end

--- Returns the path to the history file of the detected shell.
--- Respects config.options.shell_history_path when not "default".
---@return string
function M.get_shell_history_path()
	-- If user configured a path, prefer it.
	if config.options.shell_history_path ~= "default" then
		local custom = vim.fn.expand(config.options.shell_history_path)
		if not vim.uv.fs_stat(custom) then
			vim.notify(
				"[nvim-cmdlog]: Configured shell history file not found at '" .. custom .. "'.",
				vim.log.levels.WARN
			)
			return ""
		end
		return custom
	end

	local shell = M.get_shell_name()
	if shell == "" then
		return ""
	end

	if shell == "pwsh" or shell == "powershell" then
		local ps = resolve_powershell_history(shell)
		if ps == "" then
			vim.notify(
				"[nvim-cmdlog]: PowerShell PSReadLine history not found. "
				.. "Make sure PSReadLine is enabled and commands were executed at least once.",
				vim.log.levels.WARN
			)
		end
		return ps
	elseif shell == "cmd" then
		-- Try Clink history if available; otherwise cmd has no standard persistent history.
		local clink = resolve_cmd_history()
		if clink == "" then
			vim.notify(
				"[nvim-cmdlog]: 'cmd' has no standard persistent history. "
				.. "If you use Clink, its history will be used automatically when detected.",
				vim.log.levels.WARN
			)
		end
		return clink
	else
		-- POSIX-like shells via hardcoded defaults
		local path = vim.fn.expand(supported_shells[shell])
		if not vim.uv.fs_stat(path) then
			vim.notify("[nvim-cmdlog]: Default shell history file not found at '" .. path .. "'.", vim.log.levels.WARN)
			return ""
		end
		return path
	end
end

--- Parse shell history file and return only commands.
--- PowerShell: one command per line in PSReadLine history.
---@return string[] history
function M.get_shell_history()
	local history = {}
	local path = M.get_shell_history_path()
	if path == "" then
		return history
	end

	local shell = M.get_shell_name()
	if shell == "" then
		return history
	end

	-- Use special reader for PowerShell (UTF-16/BOM-aware); others can use readfile.
	local data ---@type string[]
	if shell == "pwsh" or shell == "powershell" then
		data = read_text_file_lines(path)
	else
		data = vim.fn.readfile(path)
	end

	if not data or vim.tbl_isempty(data) then
		return history
	end

	for _, line in ipairs(data) do
		if shell == "zsh" then
			-- zsh: ': 1692297413:0;command here'
			local cmd = line:match(";%s*(.*)")
			if cmd and cmd ~= "" then
				table.insert(history, cmd)
			end
		elseif shell == "bash" or shell == "ksh" or shell == "csh" then
			-- bash: either plain 'cmd' lines or '#<epoch>' timestamp markers
			if line ~= "" and not line:match("^#%d+") then
				table.insert(history, line)
			end
		elseif shell == "fish" then
			-- fish YAML-like: '- cmd: <json-escaped>'
			local cmd = line:match("^%s*%- cmd:%s*(.*)")
			if cmd and cmd ~= "" then
				-- Use JSON decoder to unescape escaped sequences
				table.insert(history, vim.fn.json_decode('"' .. cmd .. '"'))
			end
		elseif shell == "nu" then
			if line ~= "" then
				table.insert(history, line)
			end
		elseif shell == "pwsh" or shell == "powershell" then
			-- PSReadLine: one command per line; ignore empty lines.
			local cmd = trim(line)
			if cmd ~= "" then
				table.insert(history, cmd)
			end
		elseif shell == "cmd" then
			-- Clink history format: one command per line (if file exists)
			local cmd = trim(line or "")
			if cmd ~= "" then
				table.insert(history, cmd)
			end
		else
			vim.notify("[nvim-cmdlog]: Unknown shell format while parsing history.", vim.log.levels.WARN)
			break
		end
	end

	return history
end

return M
