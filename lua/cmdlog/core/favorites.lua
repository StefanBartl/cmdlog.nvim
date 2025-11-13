---@module 'cmdlog.core.favorites'
--- Manage favorites for cmdlog: load, save, toggle, and query.
--- This implementation is defensive on Windows: it normalizes/expands paths,
--- ensures parent directories exist using vim.fn.mkdir and a libuv fallback,
--- and tries a plain Lua io.open write if plenary.Path:write fails with ENOENT.
local config = require("cmdlog.config")
local Path = require("plenary.path")
local uv = vim.loop

local M = {}

---@type string[]|nil
local favorites_cache = nil

--- Helper: check if a path (string) is an existing directory
---@param p string
---@return boolean
local function is_dir(p)
	if not p or p == "" then
		return false
	end
	-- use vim.fn.isdirectory (works cross-platform)
	local ok, res = pcall(vim.fn.isdirectory, p)
	if ok then
		return res == 1
	end
	-- fallback to libuv stat
	---@diagnostic disable-next-line lib.uv
	local stat = uv.fs_stat(p)
	return stat and stat.type == "directory"
end

--- Helper: attempt to create directory via vim.fn.mkdir (recursive)
---@param p string
---@return boolean, string|nil  -- success, err_message
local function mkdir_p_vim(p)
	local ok, res = pcall(vim.fn.mkdir, p, "p")
	if ok and res == 1 then
		return true, nil
	end
	if ok and res == 0 then
		return false, "vim.fn.mkdir returned 0"
	end
	return false, tostring(res)
end

--- Helper: iterative mkdir fallback using libuv (handles Windows quirks)
--- Accepts absolute path; will create each segment if missing.
---@param abs string
---@return boolean, string|nil
local function mkdir_p_uv(abs)
	if not abs or abs == "" then
		return false, "empty path"
	end

	-- Normalize separators to platform-correct forward slashes for iteration
	local normalized = abs:gsub("\\", "/")
	-- Handle Windows drive letter "C:" prefix
	local start_ix = 1
	local base = ""
	if normalized:match("^%a:") then
		-- keep "C:" as base
		base = normalized:sub(1, 2)
		start_ix = 3
		-- add trailing slash if missing
		if normalized:sub(3, 3) == "/" then
			base = base .. "/"
			start_ix = 4
		end
	elseif normalized:sub(1, 1) == "/" then
		base = "/"
		start_ix = 2
	end

	local parts = {}
	for part in normalized:sub(start_ix):gmatch("([^/]+)") do
		table.insert(parts, part)
	end

	local cur = base
	for _, part in ipairs(parts) do
		if cur == "" or cur:sub(-1) == "/" then
			cur = cur .. part
		else
			cur = cur .. "/" .. part
		end
		-- convert to platform separator for fs calls on Windows (libuv accepts '/')
		---@diagnostic disable-next-line lib.uv
		local stat = uv.fs_stat(cur)
		if not stat then
			---@diagnostic disable-next-line lib.uv
			local ok, err = uv.fs_mkdir(cur, 511) -- 0o777 -> 511
			if not ok then
				return false, tostring(err)
			end
		end
	end
	return true, nil
end

--- Ensure the parent directory for `file_path` exists. Try multiple strategies.
---@param file_path string
---@return boolean, string|nil
local function ensure_parent_exists(file_path)
	if not file_path or file_path == "" then
		return false, "empty file_path"
	end

	-- Expand things like ~ and environment variables
	local expanded = vim.fn.expand(file_path)

	-- parent using vim.fn.fnamemodify
	local parent = vim.fn.fnamemodify(expanded, ":h")
	if parent == "" or parent == "." then
		-- nothing to create
		return true, nil
	end

	-- If already a directory, nothing to do
	if is_dir(parent) then
		return true, nil
	end

	-- 1) try vim.fn.mkdir - usually robust and cross-platform
	local ok, err = mkdir_p_vim(parent)
	if ok then
		return true, nil
	end

	-- 2) fallback: try libuv iterative mkdir
	local ok2, err2 = mkdir_p_uv(vim.fn.fnamemodify(expanded, ":p"))
	if ok2 then
		return true, nil
	end

	-- 3) final fallback: try plenary.Path:parent():mkdir (in case the above failed but plenary works)
	local ok3, res3 = pcall(function()
		local p = Path:new(expanded)
		p:parent():mkdir({ parents = true })
	end)
	if ok3 then
		return true, nil
	end

	-- aggregate error message
	local msgs = {}
	if err then
		table.insert(msgs, "vim.mkdir: " .. tostring(err))
	end
	if err2 then
		table.insert(msgs, "uv.mkdir: " .. tostring(err2))
	end
	if res3 then
		table.insert(msgs, "plenary.mkdir: " .. tostring(res3))
	end
	return false, table.concat(msgs, " | ")
end

--- Load favorites from disk (with caching)
--- @return string[] favorites or empty table
function M.load()
	if favorites_cache then
		return favorites_cache
	end

	local path = Path:new(config.options.favorites_path)

	if not path:exists() then
		favorites_cache = {}
		return favorites_cache
	end

	local ok, content = pcall(function()
		return path:read()
	end)
	if not ok or not content or content == "" then
		favorites_cache = {}
		return favorites_cache
	end

	local ok_json, decoded = pcall(vim.fn.json_decode, content)
	if not ok_json or type(decoded) ~= "table" then
		favorites_cache = {}
		return favorites_cache
	end

	favorites_cache = decoded
	return favorites_cache
end

--- Save given list of favorites to disk
--- Ensures parent directory exists, tries Path:write first and falls back to io.open if needed.
--- @param favorites string[]
function M.save(favorites)
	local target = config.options.favorites_path
	local ok_ensure, ensure_err = ensure_parent_exists(target)
	if not ok_ensure then
		vim.notify(
			("[cmdlog.favorites] Failed to ensure parent directory for '%s': %s"):format(
				tostring(target),
				tostring(ensure_err)
			),
			vim.log.levels.ERROR
		)
		-- continue to attempt write, but most likely will fail
	end

	local encoded = vim.fn.json_encode(favorites)

	-- Attempt plenary Path write (preferred)
	local path = Path:new(target)
	local ok_write, write_err = pcall(function()
		path:write(encoded, "w")
	end)

	if not ok_write then
		-- Log the plenary error and attempt plain io.open fallback
		vim.notify(
			("[cmdlog.favorites] plenary write failed for '%s': %s. Trying io.open fallback."):format(
				tostring(target),
				tostring(write_err)
			),
			vim.log.levels.WARN
		)

		-- Fallback: plain Lua file write using expanded absolute path
		local expanded = vim.fn.expand(target)
		local f_ok, f_err = pcall(function()
			-- use binary mode to avoid CRLF surprises
			local fh, ferr = io.open(expanded, "wb")
			if not fh then
				error(tostring(ferr))
			end
			fh:write(encoded)
			fh:close()
		end)
		if not f_ok then
			vim.notify(
				("[cmdlog.favorites] Fallback io.open write failed for '%s': %s"):format(
					tostring(target),
					tostring(f_err)
				),
				vim.log.levels.ERROR
			)
			return
		end
	end

	-- Update the cache after successful write
	favorites_cache = favorites
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
