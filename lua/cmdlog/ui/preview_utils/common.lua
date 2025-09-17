---@module 'cmdlog.ui.preview_utils.common'
---@brief Shared text/file/ex-command helpers for previewers.
---@description
--- DRY helpers used by both Telescope and fzf-lua previewers:
---  - string normalization / entry unwrap
---  - safe file reads
---  - safe Ex execution capture
---  - small text slicing utilities

local M = {}

---@nodiscard
---@param v any
---@return string
function M.to_s(v)
  if type(v) == "string" then return v end
  if type(v) == "table" then
    return v[1] or v.value or v.text or v.line or tostring(v)
  end
  return tostring(v or "")
end

---@nodiscard
---@param s string|nil
---@return string
function M.trim(s)
  return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

---@nodiscard
---@param s string
---@return string
function M.unwrap_cmd(s)
  s = M.trim(s)
  s = s:gsub("^%s*[★%*]%s+", "") -- drop "★ " or "* "
  s = s:gsub("^%s%s%s", "")       -- optional fixed 3-space pad
  return s
end

---@nodiscard
---@param text string|nil
---@param max integer|nil
---@return string
function M.take_lines(text, max)
  max = max or 120
  local out = { [max] = "" } -- inline reserve (perf)
  local n = 0
  for line in tostring(text or ""):gmatch("([^\n]*)\n?") do
    if line == "" and n == 0 and text == "" then break end
    n = n + 1
    if n <= max then out[n] = line else break end
  end
  if n < #out then
    for i = n + 1, #out do out[i] = nil end
  end
  return table.concat(out, "\n", 1, math.min(n, max))
end

---@nodiscard
---@param p string|nil
---@return boolean
function M.is_readable(p)
  if type(p) ~= "string" or p == "" then return false end
  return vim.fn.filereadable(p) == 1
end

---@nodiscard
---@param file string
---@param n integer
---@return string
function M.file_preview_text(file, n)
  local ok, lines = pcall(vim.fn.readfile, file, "", n)
  if not ok or type(lines) ~= "table" or #lines == 0 then
    return "[preview error] failed to read file: " .. tostring(file)
  end
  if #lines > n then return table.concat(lines, "\n", 1, n) end
  return table.concat(lines, "\n")
end

---@nodiscard
---@param excmd string
---@param max integer|nil
---@return string
function M.exec_preview_text(excmd, max)
  local ok, res = pcall(vim.api.nvim_exec2, excmd, { output = true })
  local out = (ok and res and res.output) or ""
  if out == "" then out = "[no output]" end
  return M.take_lines(out, max or 200)
end

---@nodiscard
---@param cmd string|nil
---@return string|nil
function M.extract_file_from_edit(cmd)
  cmd = tostring(cmd or "")
  local pats = {
    "^%s*:?%s*e[%w]*%s+(.+)$",
    "^%s*:?%s*sp[%w]*%s+(.+)$",
    "^%s*:?%s*vs?p?%s+(.+)$",
    "^%s*:?%s*vsplit%s+(.+)$",
  }
  for _, pat in ipairs(pats) do
    local m = string.match(cmd, pat)
    if m then
      m = m:gsub('^["\']', ""):gsub('["\']$', "")
      return vim.fn.expand(m)
    end
  end
  return nil
end

return M
