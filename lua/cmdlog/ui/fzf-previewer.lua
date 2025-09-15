---@module 'cmdlog.ui.fzf-previewer'
--- Cross-OS preview for fzf-lua builtin previewer.
--- IMPORTANT: fzf-lua's builtin previewer expects TEXT, not a command.
--- We execute the command ourselves (sync) and return its stdout as text.

local shell = require("cmdlog.core.shell")
local Job = require("plenary.job")

local M = {}

---@param v any
---@return string
local function to_s(v)
  if type(v) == "string" then return v end
  if type(v) == "table" then
    return v[1] or v.value or v.text or v.line or tostring(v)
  end
  return tostring(v or "")
end

---@param s string
---@return string
local function trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

---@param p string
---@return boolean
local function is_readable(p)
  if type(p) ~= "string" or p == "" then return false end
  return vim.fn.filereadable(p) == 1
end

---@param cmd string
---@return string|nil
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
      m = m:gsub('^["\']', ""):gsub('["\']$', "")
      return vim.fn.expand(m)
    end
  end
  return nil
end

---@param text string
---@param max integer
---@return string
local function take_lines(text, max)
  local out, n = {}, 0
  for line in tostring(text or ""):gmatch("([^\n]*)\n?") do
    if line == "" and n == 0 and text == "" then break end
    n = n + 1
    out[n] = line
    if n >= max then break end
  end
  return table.concat(out, "\n")
end

---@param argv string[]
---@param max integer
---@return string
local function run_argv(argv, max)
  max = max or 120
  -- Prefer Neovim 0.10+ sync system()
  if vim.system then
    local res = vim.system(argv, { text = true }):wait()
    local out = take_lines(res.stdout or "", max)
    if out == "" and (res.stderr or "") ~= "" then
      out = take_lines(res.stderr, max)
    end
    if out == "" then out = "[no output]" end
    return out
  end
  -- Fallback: plenary.job sync
  local cmd = table.remove(argv, 1)
  local job = Job:new({ command = cmd, args = argv })
  local ok, out = pcall(function() return job:sync() end)
  local lines = ok and out or {}
  if #lines == 0 then lines = { "[no output]" } end
  local n = math.min(#lines, max)
  return table.concat(lines, "\n", 1, n)
end

---@param variant "posix"|"powershell"|"cmd"
---@param exe string
---@param file string
---@param n integer
---@return string
local function file_preview_text(variant, exe, file, n)
  -- Pure Lua read for files (fast, portable)
  local ok, lines = pcall(vim.fn.readfile, file, "", n)
  if not ok or type(lines) ~= "table" or #lines == 0 then
    return "[preview error] failed to read file: " .. tostring(file)
  end
  return table.concat(lines, "\n")
end

---@param variant "posix"|"powershell"|"cmd"
---@param exe string
---@param bang string
---@param n integer
---@return string
local function bang_preview_text(variant, exe, bang, n)
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

--- Returns a previewer function for fzf-lua builtin previewer.
--- MUST return text (string) or nil. Do NOT return command tables here.
--- @return fun(entry: any, _: any): (string|nil)
function M.command_previewer()
  return function(entry, _)
    local cmd = trim(to_s(entry))
    local info = shell.get_shell_info()
    local variant = (info and info.variant) or "posix" ---@type "posix"|"powershell"|"cmd"
    local exe = (info and info.exe) or (variant == "powershell" and "powershell" or (variant == "cmd" and "cmd" or "sh"))

    -- File preview
    local file = extract_file_from_edit(cmd)
    if file and is_readable(file) then
      return file_preview_text(variant, exe, file, 120)
    end

    -- :! preview
    local bang = string.match(cmd, "^%s*:?%s*!%s*(.+)$")
    if bang and bang ~= "" then
      return bang_preview_text(variant, exe, bang, 120)
    end

    -- Return nil to show nothing
    return nil
  end
end

return M
