---@module 'cmdlog.ui.preview_utils.short_ex'

--- Adds a "short Ex command" branch that explains terse commands like
---   w / w! / q / q! / x / x! / wa / wq / wqa / bd / e / sp / vs / p / r / b / ls
--- instead of executing them. It optionally tries to resolve a related help topic.

-- ---------------------------------------------------------------------------
-- Short Ex command explainer
-- ---------------------------------------------------------------------------

local M = {}

local help = require("cmdlog.ui.preview_utils.help")

---@type table<string, ShortExInfo>
local SHORT_EX = {
  -- Writing / quitting
  ["w"]    = { label = ":w",    help = ":w",        desc = "Write current buffer to its file (fails if 'readonly' or no write permission)." },
  ["w!"]   = { label = ":w!",   help = ":w!",       desc = "Force write current buffer (overrides 'readonly' / permissions where applicable)." },
  ["wa"]   = { label = ":wa",   help = ":wa",       desc = "Write all modified buffers." },
  ["wa!"]  = { label = ":wa!",  help = ":wa!",      desc = "Force write all modified buffers." },
  ["wq"]   = { label = ":wq",   help = ":wq",       desc = "Write current buffer, then quit current window." },
  ["wq!"]  = { label = ":wq!",  help = ":wq!",      desc = "Force write current buffer, then quit." },
  ["wqa"]  = { label = ":wqa",  help = ":wqa",      desc = "Write all modified buffers and quit Vim." },
  ["wqa!"] = { label = ":wqa!", help = ":wqa",      desc = "Force write all modified buffers and quit Vim." },
  ["x"]    = { label = ":x",    help = ":x",        desc = "Write if modified, then quit (like :wq but skips write when unmodified)." },
  ["x!"]   = { label = ":x!",   help = ":x",        desc = "Force write if modified, then quit." },
  ["q"]    = { label = ":q",    help = ":q",        desc = "Quit current window (fails if there are unsaved changes)." },
  ["q!"]   = { label = ":q!",   help = ":q!",       desc = "Quit discarding changes in the current buffer." },
  ["qa"]   = { label = ":qa",   help = ":qa",       desc = "Quit all windows (fails if unsaved changes exist)." },
  ["qa!"]  = { label = ":qa!",  help = ":qa!",      desc = "Quit all windows discarding changes." },

  -- Buffers / editing
  ["bd"]   = { label = ":bd",   help = ":bdelete",  desc = "Delete (unload) the current buffer from the buffer list; window may remain." },
  ["bd!"]  = { label = ":bd!",  help = ":bdelete",  desc = "Force delete the current buffer; may discard changes." },
  ["b"]    = { label = ":b",    help = ":b",        desc = "Switch to another buffer by number or unique name fragment." },
  ["e"]    = { label = ":e",    help = ":edit",     desc = "Edit a file (reload current if no argument). Discards changes unless written." },
  ["e!"]   = { label = ":e!",   help = ":edit!",    desc = "Edit/reload discarding changes in current buffer." },

  -- Windows / splits
  ["sp"]   = { label = ":sp",   help = ":split",    desc = "Split the current window horizontally; optionally open a file in the new split." },
  ["vs"]   = { label = ":vs",   help = ":vsplit",   desc = "Split the current window vertically; optionally open a file in the new split." },
  ["vsp"]  = { label = ":vsp",  help = ":vsplit",   desc = "Alias of :vsplit." },

  -- Reading / printing
  ["r"]    = { label = ":r",    help = ":read",     desc = "Read a file or command output and insert it below the current line." },
  ["p"]    = { label = ":p",    help = ":print",    desc = "Print (display) the current line or a given range (Ex 'print')." },

  -- Listings
  ["ls"]   = { label = ":ls",   help = ":ls",       desc = "List buffers with their numbers, flags and names (alias :buffers)." },
}

---@nodiscard
---@param s string
---@return string
-- Normalize a short Ex token for table lookup:
--   * Lowercase
--   * Collapse multiple spaces
--   * Preserve trailing '!' as part of the key (e.g. 'w!' distinct from 'w')
local function norm_short_ex_key(s)
  s = tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
  s = s:lower():gsub("%s+", " ")
  return s
end

---@nodiscard
---@param cmd string
---@return string|nil
-- Try to describe a short Ex command without executing it.
-- Flow:
--   1) Extract head token (first word after optional ":"), keep an optional trailing "!".
--   2) Lookup in SHORT_EX; if found, return a textual explanation block.
--   3) If not found, attempt a heuristic help tag:
--        • Prefer mapping "p" -> ":print", "bd" -> ":bdelete", "e" -> ":edit", "sp"->":split", "vs|vsp"->":vsplit"
--        • Else try a generic ":<token>" tag.
--      If help is found, return its sliced text; otherwise nil.
function M.try_preview(cmd)
  -- Extract head incl. optional bang, e.g. "w!", "bd", "vs"
  local head = cmd:match("^%s*:?%s*([%w%p]+)") or ""
  head = norm_short_ex_key(head)

  -- direct table hit
  local info = SHORT_EX[head]
  if info then
    -- Human-readable explainer first; help excerpt appended if available
    local lines = { [4] = "" }
    lines[1] = info.label .. " — " .. info.desc
    if info.help then
      local ok, help_text = pcall(function() return help.try_preview(info.help, 80) end)
      if ok and type(help_text) == "string" and help_text ~= "" then
        lines[2] = ""
        lines[3] = help_text
        return table.concat(lines, "\n")
      end
    end
    return table.concat(lines, "\n")
  end

  -- Heuristic help fallback for unknown tokens
  local alias = ({
    p   = ":print",
    bd  = ":bdelete",
    e   = ":edit",
    ["e!"]  = ":edit!",
    sp  = ":split",
    vs  = ":vsplit",
    vsp = ":vsplit",
  })[head]

  local tag = alias or (":" .. head)
  local ok, help_text = pcall(function() return help.try_preview(tag, 80) end)
  if ok and type(help_text) == "string" and help_text ~= "" and not help_text:match("^%[help%] tag not found") then
    return help_text
  end

  return nil
end

return M
