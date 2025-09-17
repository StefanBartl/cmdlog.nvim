---@module 'cmdlog.ui.fzf_previewer'
--- Text-returning previewer for fzf-lua pickers.

local shell = require("cmdlog.core.shell") ---@module 'cmdlog.core.shell'
local Job = require("plenary.job") ---@module 'plenary.job'
local excmds = require("cmdlog.ui.preview_utils.excommands_utils")
local short_ex = require("cmdlog.ui.preview_utils.short_ex")
local echo = require("cmdlog.ui.preview_utils.echo")
local help = require("cmdlog.ui.preview_utils.help")
local usercmd = require("cmdlog.ui.preview_utils.usercommands")

---@alias CmdlogString string
---@alias CmdlogInteger integer

---@class CmdlogPreviewer
local M = {}

-- ---------- small utils ----------

---@nodiscard
---@param v any
---@return string
--- Convert a value to string with a few common table-shapes unwrapped first.
--- Special handling:
---   * If `v` is a table that looks like { text = "…" } or { value = "…" } etc.,
---     try to pick that primary field for a cleaner preview.
local function to_s(v)
	if type(v) == "string" then
		return v
	end
	if type(v) == "table" then
		return v[1] or v.value or v.text or v.line or tostring(v)
	end
	return tostring(v or "")
end

---@nodiscard
---@param s string|nil
---@return string
--- Trim leading and trailing whitespace via pattern substitution.
--- Note: Uses two passes (left, right) for clarity and speed on short strings.
local function trim(s)
	return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

---@nodiscard
---@param s string
---@return string
--- Remove UI decorations from a command string as used in list UIs:
---   * Leading "★ " or "* " favorites marker
---   * Optional fixed 3-space padding
--- This keeps the function robust to both "fav" and "non-fav" shapes produced by upstream lists.
local function unwrap_cmd(s)
	s = trim(s)
	s = s:gsub("^%s*[★%*]%s+", "") -- drop "★ " or "* "
	s = s:gsub("^%s%s%s", "") -- or 3-space pad (non-fav)
	return s
end

---@nodiscard
---@param p string|nil
---@return boolean
--- Lightweight readability probe using VimL's `filereadable()` for better cross-platform handling
--- (works consistently with ~, symlinks, and Windows drive paths after expand()).
local function is_readable(p)
	if type(p) ~= "string" or p == "" then
		return false
	end
	return vim.fn.filereadable(p) == 1
end

---@nodiscard
---@param cmd string|nil
---@return string|nil
--- Try to extract a file path from common `:edit`-like commands:
---   * :e / :edit
---   * :sp / :split
---   * :vs / :vsplit / :vsp
--- Implementation detail:
---   * Uses anchored patterns so we do not accidentally match words inside arguments.
---   * Strips single/double quotes and resolves `~` etc. via `expand()`.
local function extract_file_from_edit(cmd)
	cmd = tostring(cmd or "")
	local patterns = {
		"^%s*:?%s*e[%w]*%s+(.+)$",
		"^%s*:?%s*sp[%w]*%s+(.+)$",
		"^%s*:?%s*vs?p?%s+(.+)$",
		"^%s*:?%s*vsplit%s+(.+)$",
	}
	for _, pat in ipairs(patterns) do
		local m = string.match(cmd, pat)
		if m then
			m = m:gsub("^[\"']", ""):gsub("[\"']$", "")
			return vim.fn.expand(m)
		end
	end
	return nil
end

---@nodiscard
---@param text string|nil
---@param max integer|nil
---@return string
--- Efficiently take the first `max` lines from `text`.
--- Performance note:
---   * Uses an inline-reserved table `{ [max] = "" }` to minimize re-allocations as requested.
---   * Avoids building huge temporary arrays for long outputs by an early stop at `max`.
local function take_lines(text, max)
	max = max or 120
	local out = { [max] = "" } -- inline reserve
	local n = 0
	for line in tostring(text or ""):gmatch("([^\n]*)\n?") do
		if line == "" and n == 0 and text == "" then
			break
		end
		n = n + 1
		if n <= max then
			out[n] = line
		else
			break
		end
	end
	if n < #out then
		for i = n + 1, #out do
			out[i] = nil
		end
	end
	return table.concat(out, "\n", 1, math.min(n, max))
end

---@nodiscard
---@param argv string[]
---@param max integer|nil
---@return string
--- Run a command vector and capture up to `max` lines.
--- Strategy:
---   * Prefer `vim.system()` (Neovim ≥0.10) for robust async-with-wait and proper text mode.
---   * Fallback to `plenary.job` if `vim.system` is unavailable.
--- Behavior:
---   * If stdout is empty but stderr has content, return stderr (useful for command errors).
---   * Guarantees a non-empty result by returning "[no output]" when both streams are empty.
local function run_argv(argv, max)
	max = max or 120
	if vim.system then
		local res = vim.system(argv, { text = true }):wait()
		local out = take_lines(res.stdout or "", max)
		if out == "" and (res.stderr or "") ~= "" then
			out = take_lines(res.stderr, max)
		end
		if out == "" then
			out = "[no output]"
		end
		return out
	end
	-- Fallback: plenary.job
	local cmd = table.remove(argv, 1)
	local job = Job:new({ command = cmd, args = argv })
	local ok, out = pcall(function()
		return job:sync()
	end)
	local lines = ok and out or {}
	if #lines == 0 then
		lines = { "[no output]" }
	end
	local n = math.min(#lines, max)
	return table.concat(lines, "\n", 1, n)
end

---@nodiscard
---@param file string
---@param n integer
---@return string
--- Read up to `n` lines from `file`.
--- Error handling:
---   * Uses `pcall(vim.fn.readfile, ...)` so we never throw; returns a readable error token otherwise.
local function file_preview_text(file, n)
	local ok, lines = pcall(vim.fn.readfile, file, "", n)
	if not ok or type(lines) ~= "table" or #lines == 0 then
		return "[preview error] failed to read file: " .. tostring(file)
	end
	if #lines > n then
		return table.concat(lines, "\n", 1, n)
	end
	return table.concat(lines, "\n")
end

---@nodiscard
---@param exe string|nil
---@param variant "powershell"|"cmd"|"posix"
---@param bang string
---@param n integer
---@return string
--- Execute a :!bang command with the correct shell wrapper per platform:
---   * PowerShell: `powershell -NoProfile -Command <bang>`
---   * cmd.exe:    `cmd /C <bang>`
---   * POSIX sh:   `sh -c <bang>`
local function bang_preview_text(exe, variant, bang, n)
	local argv
	if variant == "powershell" then
		argv = { exe or "powershell", "-NoProfile", "-Command", bang }
	elseif variant == "cmd" then
		argv = { exe or "cmd", "/C", bang }
	else
		argv = { exe or "sh", "-c", bang }
	end
	return run_argv(argv, n)
end

---@nodiscard
---@param excmd string
---@param max integer|nil
---@return string
--- Execute an Ex command and return its text output.
local function exec_preview_text(excmd, max)
	local ok, res = pcall(vim.api.nvim_exec2, excmd, { output = true })
	local out = (ok and res and res.output) or ""
	if out == "" then
		out = "[no output]"
	end

	return take_lines(out, max or 200)
end

-- ---------------------------------------------------------------------------
-- main previewer (patched branch inserted as requested)
-- ---------------------------------------------------------------------------

---@nodiscard
---@return fun(entry:any, ctx:any):string
--- AUDIT:
--- Build the previewer closure for fzf-lua.
--- Control flow (ordered checks):
---   1) Normalize the entry to a command string.
---   2) If it is an introspection command:
---        • Special-case ":messages": if a "messages UI" is active (e.g., noice), return a disabled note.
---      Rationale: This avoids opening the messages window during preview selection.
---   3) If it is `:help {topic}`: resolve and slice the doc section.
---   4) If it is any other safe introspection command: exec-capture text via `nvim_exec2`.
---   5) If it looks like an edit/split/vsplit with a file: read the first lines of the file.
---   6) If it is a bang `:!` command: execute in the appropriate shell wrapper and capture output.
---   7) Fallback: "[no preview]".
function M.command_previewer()
	return function(entry, _)
		-- normalize
		local raw = to_s(entry)
		local cmd = unwrap_cmd(raw)
		-- local head = excmds.head_token(cmd)            ---@type string  -- cached once
		local exhead = (excmds.ex_head_after_mods(cmd)):lower() ---@type string -- compute Ex head AFTER modifiers once (robuster als head_token)

		-- Resolve shell info once for :!bang invocations (lazy use below).
		local info = shell.get_shell_info()
		local variant = (info and info.variant) or "posix"
		local exe = (info and info.exe)
			or (variant == "powershell" and "powershell" or (variant == "cmd" and "cmd" or "sh"))

		-- -----------------------------------------------------------------
		-- :help {topic}
		-- -----------------------------------------------------------------
		--  BUG: more restrictive: only capture :h & :help
		local help_topic = cmd:match("^%s*:?%s*h%w*%s+(.+)$")
		if help_topic then
			return help.try_preview(help_topic, 120) or "[no preview] for this help tag"
		end

		-- -----------------------------------------------------------------
		-- echo branch
		-- -----------------------------------------------------------------
		do
			local echo_text = echo.try_preview(cmd)
			if echo_text ~= nil then
				-- Never return nil; echo_text may be empty string if nothing after 'echo'
				return echo_text ~= "" and echo_text or "[empty echo]"
			end
		end

		-- 3) NEW: user-command branch (global + buffer-local)
		do
			local u = usercmd.try_preview(cmd)
			if u and u ~= "" then
				return u
			end
		end
		-- -----------------------------------------------------------------------
		-- Introspection commands
		-- -----------------------------------------------------------------------

		if excmds.SAFE[exhead] or excmds.is_messages_ex(cmd) then
			if exhead == "messages" then
				local protection = require("cmdlog.ui.preview_utils.noice_detection")
				if protection.is_noice_messages_enabled({ soft = true }) then
					return "[no preview] ':messages' preview disabled if 'noice.messages' is active"
				end
				return exec_preview_text("silent messages", 200)
			end
			return exec_preview_text(cmd, 200)
		end

		-- -----------------------------------------------------------------------
		-- Short-Ex-Erklärer (w, q, bd, p, …) – NACH Introspection,
		-- -----------------------------------------------------------------------
		do
			local explained = short_ex.try_preview(cmd)
			if explained and explained ~= "" then
				return explained
			end
		end

		-- -----------------------------------------------------------------
		-- File previews from edit-like commands
		-- -----------------------------------------------------------------
		local file = extract_file_from_edit(cmd)
		if file and is_readable(file) then
			return file_preview_text(file, 120)
		end

		-- -----------------------------------------------------------------
		-- :!bang commands
		-- -----------------------------------------------------------------
		local bang = string.match(cmd, "^%s*:?%s*!%s*(.+)$")
		if bang and bang ~= "" then
			return bang_preview_text(exe, variant, bang, 120)
		end

		-- Final fallback to avoid nil returns in fzf-lua previewers
		return "[no preview]"
	end
end

return M
