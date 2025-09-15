---@module 'cmdlog.normalize'
--- Normalization helpers for command strings used in favorites toggling.
--- Strips UI markers (★, ☆, , *), unwraps common shell wrappers, trims and collapses whitespace.

---@class CmdlogNormalize
local N = {}

---@nodiscard
---@param s string
---@return string
local function trim_spaces(s)
  -- collapse internal whitespace and trim ends
  s = s:gsub("%s+", " ")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s
end

---@nodiscard
---@param s string
---@return string
function N.strip_ui_markers(s)
  -- Remove favorite/star markers or bullets at the very start, then any following spaces.
  -- Extend the class if more icons are used in the UI list.
  -- Included: U+2605 ★, U+2606 ☆, Nerd Font U+F005 , ASCII *
  s = s:gsub("^%s*[★☆%*]+%s*", "")
  -- Optional: generic bullets/dashes used by some lists
  s = s:gsub("^%s*[•·%-]+%s*", "")
  return s
end

---@nodiscard
---@param s string
---@return string
function N.unwrap_wrappers(s)
  -- cmd.exe /C "..."  → ...
  s = s:gsub([[^%s*[Cc][Mm][Dd]%.?[Ee]?[Xx]?[Ee]?%s+/%s*[Cc]%s+"?([^"]+)"?%s*$]], "%1")

  -- sh -c "..." or bash/zsh -lc "..." → ...
  s = s:gsub([[^%s*[%w%./_-]*sh%s+%-[lc]%s+"?([^"]+)"?%s*$]], "%1")

  -- powershell(.exe) ... -Command "..." → ...
  -- Accept arbitrary flags before -Command
  s = s:gsub([[^%s*[Pp]ower[Ss]hell%.?[Ee]?[Xx]?[Ee]?[%s%-%w/]*%-[Cc]ommand%s+"?([^"]+)"?%s*$]], "%1")

  return s
end

---@nodiscard
---@param s any
---@return string
function N.normalize(s)
  if type(s) ~= "string" then return "" end
  -- strip zero-width and control characters defensively
  s = s:gsub("[%z\1-\31\194\128\139\194\128\140\194\128\141\239\187\191]", "")
  s = N.strip_ui_markers(s)
  s = N.unwrap_wrappers(s)
  s = trim_spaces(s)
  return s
end

return N

