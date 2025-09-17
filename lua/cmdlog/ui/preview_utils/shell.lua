---@module 'cmdlog.ui.preview_utils.shell'
---@brief Portable shell execution helpers for previews.
---@description
--- Provides argv runner and :!bang wrapper selection for Windows (cmd/pwsh) and POSIX.

local Job = require("plenary.job")
local common = require("cmdlog.ui.preview_utils.common")

local M = {}

---@nodiscard
---@param argv string[]
---@param max integer|nil
---@return string
function M.run_argv(argv, max)
  max = max or 120
  if vim.system then
    local res = vim.system(argv, { text = true }):wait()
    local out = common.take_lines(res.stdout or "", max)
    if out == "" and (res.stderr or "") ~= "" then
      out = common.take_lines(res.stderr, max)
    end
    if out == "" then out = "[no output]" end
    return out
  end
  -- Fallback: plenary.job
  local cmd = table.remove(argv, 1)
  local job = Job:new({ command = cmd, args = argv })
  local ok, lines = pcall(function() return job:sync() end)
  lines = ok and lines or {}
  if #lines == 0 then lines = { "[no output]" } end
  local n = math.min(#lines, max)
  return table.concat(lines, "\n", 1, n)
end

---@nodiscard
---@param exe string|nil
---@param variant "powershell"|"cmd"|"posix"
---@param bang string
---@param n integer
---@return string
function M.bang_preview_text(exe, variant, bang, n)
  local argv
  if variant == "powershell" then
    argv = { exe or "powershell", "-NoProfile", "-Command", bang }
  elseif variant == "cmd" then
    argv = { exe or "cmd", "/C", bang }
  else
    argv = { exe or "sh", "-c", bang }
  end
  return M.run_argv(argv, n)
end

return M

