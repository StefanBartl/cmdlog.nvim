---@module 'cmdlog.core.favorites'
--- Manage favorites for cmdlog: load, save, toggle, and query.
--- Directory creation and cross-platform write handling is delegated to
--- lib.nvim (lib.nvim.fs.write.to_file), which already covers the
--- Windows/Unix mkdir edge cases this module used to reimplement.
local config = require("cmdlog.config")
local Path = require("plenary.path")
local write_to_file = require("lib.nvim.fs.write.to_file")
local find_upward_dir = require("lib.nvim.fs.find_upward_dir")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.favorites]")

local M = {}

--- Tiny deterministic string hash (djb2-ish), used to keep per-project
--- favorites filenames short while still unique per Git root path.
---@param s string
---@return string
local function short_hash(s)
	local h = 5381
	for i = 1, #s do
		h = (h * 33 + s:byte(i)) % 0xFFFFFFFF
	end
	return string.format("%08x", h)
end

--- Resolves the effective favorites.json path for the current context.
--- Global by default; if `project_scoped.enabled` is set and a Git root is
--- found upward from cwd, a dedicated per-project file is used instead.
---@return string
local function get_favorites_path()
	local opts = config.options
	local scoped = opts.project_scoped

	if type(scoped) == "table" and scoped.enabled then
		local root = find_upward_dir({ ".git" }, vim.fn.getcwd())
		if root then
			local base_dir = vim.fn.fnamemodify(vim.fn.expand(opts.favorites_path), ":h")
			local project_name = vim.fs.basename(root):gsub("[^%w%-_.]", "_")
			return base_dir .. "/projects/" .. project_name .. "-" .. short_hash(root) .. ".json"
		end
	end

	return opts.favorites_path
end

---@type table<string, string[]>
local favorites_cache = {}

--- Load favorites from disk (with caching, keyed by the resolved path so
--- switching projects doesn't leak favorites between them).
--- @return string[] favorites or empty table
function M.load()
	local target = get_favorites_path()

	if favorites_cache[target] then
		return favorites_cache[target]
	end

	local path = Path:new(target)

	if not path:exists() then
		favorites_cache[target] = {}
		return favorites_cache[target]
	end

	local ok, content = pcall(function()
		return path:read()
	end)
	if not ok or not content or content == "" then
		favorites_cache[target] = {}
		return favorites_cache[target]
	end

	local ok_json, decoded = pcall(vim.fn.json_decode, content)
	if not ok_json or type(decoded) ~= "table" then
		favorites_cache[target] = {}
		return favorites_cache[target]
	end

	favorites_cache[target] = decoded
	return favorites_cache[target]
end

--- Save given list of favorites to disk.
--- Ensures the parent directory exists and writes the file (via lib.nvim).
--- @param favorites string[]
function M.save(favorites)
	local target = vim.fn.expand(get_favorites_path())
	local encoded = vim.fn.json_encode(favorites)

	local ok, err = write_to_file(target, encoded)
	if not ok then
		notify.error(("Failed to write favorites to '%s': %s"):format(target, tostring(err)))
		return
	end

	favorites_cache[target] = favorites
end

--- Toggle a command in favorites
--- @param cmd string
function M.toggle(cmd)
	local favs = M.load()
	---@type string[]
	local new = {}

	local found = false
	for _, entry in ipairs(favs) do
		if entry == cmd then
			found = true
		else
			table.insert(new, entry)
		end
	end

	if not found then
		table.insert(new, cmd)
	end

	M.save(new)
end

--- Check if a command is a favorite
--- @param cmd string
--- @return boolean
function M.is_favorite(cmd)
	local favs = M.load()
	for _, entry in ipairs(favs) do
		if entry == cmd then
			return true
		end
	end
	return false
end

return M
