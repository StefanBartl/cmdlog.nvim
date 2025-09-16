---@module 'cmdlog.ui.preview_utils.echo'

--- Echo-text extraction (for both ":echo …" and ":!echo …") which
--- avoids execution and instead returns the argument text inside quotes.
--- Notes:
---   * Supports double and single quotes, including \" or \' escapes.
---   * If multiple quoted segments appear, they are joined with a single space.
---   * If no quotes are present, falls back to the raw text after the "echo" token.
---   * This branch runs BEFORE generic :!bang execution to prevent side effects.

local M = {}

-- =====================================================================
-- Echo parser utilities
-- =====================================================================

---@nodiscard
---@param s string|nil
---@return string
-- Extract the substring right after the 'echo' head token (for both Vim :echo and shell echo).
-- Implementation details:
--   * Matches at start with optional leading ":".
--   * Accepts any spacing and stops at end of line.
--   * Returns empty string if no 'echo' token is found.
local function extract_after_echo_head(s)
  s = tostring(s or "")
  -- 1) Vim-style: ":echo ..." or "echo ..."
  local rest = s:match("^%s*:?%s*echo%s+(.*)$")
  if rest and rest ~= "" then
    return rest
  end
  -- 2) Bang-style: ":!echo ..." or "!echo ..."
  rest = s:match("^%s*:?%s*!%s*echo%s+(.*)$")
  return rest or ""
end

---@nodiscard
---@param s string
---@return string[]
-- Collect ALL quoted segments from `s`. Supports:
--   * Double quotes "…", with backslash-escaping of \".
--   * Single quotes '…', with backslash-escaping of \'.
-- Unusual flow:
--   * Lua patterns do not handle backslash-escaping elegantly, so this uses a small
--     state-machine scanner. It is linear-time and avoids intermediate string builds.
local function collect_quoted_segments(s)
  local res = {} ---@type string[]
  local i, n = 1, #s
  local q = nil     ---@type string|nil  -- current quote char: "'" or '"'
  local buf = {}    ---@type string[]    -- buffer for current segment

  while i <= n do
    local c = s:sub(i, i)
    if not q then
      -- Not inside a quoted segment: look for opening quote
      if c == '"' or c == "'" then
        q = c
        buf = {}
      end
    else
      -- Inside quoted segment delimited by `q`
      if c == "\\" then
        -- Escape sequence: include next char verbatim if present
        local nx = s:sub(i + 1, i + 1)
        if nx ~= "" then
          buf[#buf + 1] = nx
          i = i + 1
        end
      elseif c == q then
        -- Closing quote: commit segment
        res[#res + 1] = table.concat(buf)
        q = nil
        buf = {}
      else
        buf[#buf + 1] = c
      end
    end
    i = i + 1
  end

  -- If an unterminated quote exists, commit what we have (best-effort)
  if q and #buf > 0 then
    res[#res + 1] = table.concat(buf)
  end
  return res
end

---@nodiscard
---@param s string
---@return string
-- Fallback extraction if no quotes exist: return the trimmed remainder after echo,
-- but strip leading/trailing whitespace and one optional surrounding pair of quotes if present.
-- This makes ":echo foo", ":!echo bar", "echo    baz" still show something meaningful.
local function fallback_echo_text(s)
  -- Remove optional surrounding quotes once
  s = s:gsub("^%s*", ""):gsub("%s*$", "")
  s = s:gsub([[^"(.*)"$]], "%1"):gsub([[^'(.*)'$]], "%1")
  return s
end

---@nodiscard
---@param cmd string
---@return string|nil
-- High-level echo previewer:
--   1) Detect whether the command is ":echo …" or ":!echo …".
--   2) Extract text after the 'echo' head.
--   3) Collect quoted segments; if any found, join by single space and return.
--   4) Else return a trimmed fallback of the remainder.
-- Returns nil if this is not an echo command, so callers can continue other branches.
function M.try_preview(cmd)
  -- Probe head first to avoid false positives (e.g., filenames containing the word "echo").
  local is_vim_echo = cmd:match("^%s*:?%s*echo%f[%W]") ~= nil
  local is_bang_echo = cmd:match("^%s*:?%s*!%s*echo%f[%W]") ~= nil
  if not (is_vim_echo or is_bang_echo) then
    return nil
  end

  local rest = extract_after_echo_head(cmd)
  if rest == "" then
    return ""
  end

  local parts = collect_quoted_segments(rest)
  if #parts > 0 then
    return table.concat(parts, " ")
  end

  return fallback_echo_text(rest)
end

return M
