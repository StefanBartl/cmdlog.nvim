---@module 'cmdlog.ui.preview_utils'
-- ---------- :help {topic} ----------

local M = {}

---@nodiscard
---@param s string
---@return string
--- Escape Lua pattern punctuation for safe literal matching inside help docs.
local function lua_pat_escape(s)
	return (s:gsub("(%p)", "%%%1"))
end

---@nodiscard
---@param topic string|nil
---@param max integer|nil
---@return string|nil
--- Locate a help tag and return `max` lines from its anchor onward.
--- Implementation details:
---   * Iterates over all runtime `doc/tags`, picks the doc file for `topic`,
---     then finds the `*topic*` anchor and slices lines from there.
---   * Returns a friendly token if the tag does not exist.
function M.try_preview(topic, max)
	topic = tostring(topic or ""):gsub("^[\"']", ""):gsub("[\"']$", "")
	if topic == "" then
		return nil
	end

	local tagfiles = vim.api.nvim_get_runtime_file("doc/tags", true)
	for _, tagfile in ipairs(tagfiles) do
		local ok, tlines = pcall(vim.fn.readfile, tagfile)
		if ok and type(tlines) == "table" then
			for _, L in ipairs(tlines) do
				local tag, file = L:match("^([^\t]+)\t([^\t]+)\t")
				if tag == topic and file and file ~= "" then
					local docdir = vim.fn.fnamemodify(tagfile, ":h")
					local doc = docdir .. "/" .. file
					local ok2, dlines = pcall(vim.fn.readfile, doc)
					if ok2 and type(dlines) == "table" and #dlines > 0 then
						local anchor = "%*" .. lua_pat_escape(topic) .. "%*"
						local start = 1
						for i = 1, #dlines do
							if dlines[i]:find(anchor) then
								start = i
								break
							end
						end
						local last = math.min(#dlines, start + (max or 120) - 1)
						return table.concat(dlines, "\n", start, last)
					end
				end
			end
		end
	end
	return "[help] tag not found: " .. topic
end

return M
