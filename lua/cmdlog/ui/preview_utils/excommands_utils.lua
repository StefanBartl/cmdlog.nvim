---@module 'cmdlog.ui.preview_utils.excommands_utils'
-- ---------- Exec-captured preview for safe introspection commands ----------

local Excommands = {}

---@nodiscard
---@param cmd string
---@return string head, string[] mods
-- Parse the first Ex command token after skipping common modifiers.
-- Examples:
--   ":messages"              -> "messages"
--   ":silent messages"       -> "messages"
--   ":silent!   messages"    -> "messages"
--   "vertical keepalt foo"   -> "foo"
function Excommands.ex_head_after_mods(cmd)
  local s = tostring(cmd or ""):gsub("^%s*:%s*", "")
  local mods = {} ---@type string[]
  -- Common Ex modifiers; extend as needed
  local MODS = {
    silent = true, ["silent!"] = true, unsilent = true,
    keepalt = true, keepjumps = true, keeppatterns = true,
    lockmarks = true, nomodifiable = true, sandbox = true, confirm = true,
    aboveleft = true, belowright = true, leftabove = true, rightbelow = true,
    vertical = true, tab = true, keepmarks = true,
  }
  for tok in s:gmatch("(%S+)") do
    local t = tok:lower()
    if MODS[t] then
      mods[#mods + 1] = t
    else
      return tok, mods
    end
  end
  return "", mods
end

---@nodiscard
---@param cmd string
---@return boolean
-- Recognize ":messages" with optional leading modifiers like "silent" or "silent!"
-- Examples matched:
--   :messages
--   messages
--   :silent messages
--   :silent!   messages
-- The pattern anchors at start (optional ":" / WS), then zero+ "silent"(!) blocks, then "messages" as a word.
function Excommands.is_messages_ex(cmd)
  return tostring(cmd or ""):match("^%s*:?%s*(silent!?%s+)*messages%f[%W]") ~= nil
end

---@class CmdlogSafeSet
---@field [string] boolean

---@type CmdlogSafeSet
Excommands.SAFE = {
	messages = true,
	registers = true,
	marks = true,
	jumps = true,
	changes = true,
	["ls"] = true,
	buffers = true,
	scriptnames = true,
	set = true,
	setlocal = true,
	setglobal = true,
	map = true,
	nmap = true,
	imap = true,
	vmap = true,
	xmap = true,
	smap = true,
	omap = true,
	tmap = true,
	noremap = true,
	nnoremap = true,
	inoremap = true,
	vnoremap = true,
	xnoremap = true,
	snoremap = true,
	onoremap = true,
	tnoremap = true,
	autocmd = true, -- extend as needed
}

---@nodiscard
---@param cmd string|nil
---@return string
--- Extract the head token (first non-space word after optional `:`), lowercased.
function Excommands.head_token(cmd)
	local s = tostring(cmd or "")
	s = s:match("^%s*:?%s*(%S+)") or ""
	return s:lower()
end

return Excommands
