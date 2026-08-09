---@module 'cmdlog.core.favorites'
--- Manage favorites for cmdlog: load, save, toggle, and query.
--- All filesystem I/O goes through lib.nvim (fs.is_readable_file, fs.read,
--- fs.write.to_file) instead of plenary.path, so this module carries no
--- plenary.nvim dependency.
local config = require("cmdlog.config")
local is_readable_file = require("lib.nvim.fs.is_readable_file")
local read_file = require("lib.nvim.fs.read")
local write_to_file = require("lib.nvim.fs.write.to_file")
local find_upward_dir = require("lib.nvim.fs.find_upward_dir")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.favorites]")

local M = {}

--- Tiny deterministic string hash (djb2-ish), used to keep per-project
--- favorites filenames short while still unique per Git root path.
---@internal
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
---@internal
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

-- Snapshot of the favorites list taken right before the most recent
-- M.toggle(), keyed by the resolved path it applied to. Session-local
-- (not persisted) and single-level: only the last toggle can be undone.
---@type { path: string, list: string[] }|nil
local last_toggle_snapshot = nil

--- Load favorites from disk (with caching, keyed by the resolved path so
--- switching projects doesn't leak favorites between them).
--- @return string[] favorites or empty table
function M.load()
  -- Expanded, matching M.save()'s cache key -- on Windows, vim.fn.expand()
  -- can change a path (e.g. normalizing `/` to `\` in a vim.fn.tempname()
  -- style path), so an unexpanded key here would miss both the cache and
  -- the on-disk file that M.save() actually wrote.
  local target = vim.fn.expand(get_favorites_path())

  if favorites_cache[target] then return favorites_cache[target] end

  if not is_readable_file(target) then
    favorites_cache[target] = {}
    return favorites_cache[target]
  end

  local content = read_file(target)
  if not content or content == "" then
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
  last_toggle_snapshot = { path = vim.fn.expand(get_favorites_path()), list = vim.deepcopy(favs) }

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

  if not found then table.insert(new, cmd) end

  M.save(new)
end

--- Undo the most recent M.toggle(), restoring the favorites list as it was
--- right before that call. Single-level: only the last toggle is
--- remembered, and only for the project/global file it applied to.
--- @return boolean ok false if there's nothing to undo (or the resolved
---   favorites path has since changed, e.g. a project switch)
function M.undo_last_toggle()
  if not last_toggle_snapshot then return false end
  if last_toggle_snapshot.path ~= vim.fn.expand(get_favorites_path()) then return false end

  M.save(last_toggle_snapshot.list)
  last_toggle_snapshot = nil
  return true
end

--- Move a favorite one slot up (`offset = -1`) or down (`offset = 1`) in
--- the persisted list order. No-op (returns false) if `cmd` isn't a
--- favorite or is already at that end of the list.
--- @param cmd string
--- @param offset -1|1
--- @return boolean ok
function M.move(cmd, offset)
  local favs = vim.deepcopy(M.load())

  local idx = nil
  for i, entry in ipairs(favs) do
    if entry == cmd then
      idx = i
      break
    end
  end
  if not idx then return false end

  local target = idx + offset
  if target < 1 or target > #favs then return false end

  favs[idx], favs[target] = favs[target], favs[idx]
  M.save(favs)
  return true
end

--- Default export path: same directory/basename as the resolved favorites
--- file, with a `.export.json` suffix so it never collides with the live
--- file.
---@internal
---@return string
local function default_export_path()
  local base = (get_favorites_path():gsub("%.json$", ""))
  return base .. ".export.json"
end

--- Export the current favorites list to a JSON file for backup or transfer
--- between machines (e.g. laptop <-> workstation).
--- @param path? string Defaults to the favorites file's path + `.export.json`
--- @return boolean ok
function M.export(path)
  local target = vim.fn.expand(path and path ~= "" and path or default_export_path())
  local favs = M.load()
  local encoded = vim.fn.json_encode(favs)

  local ok, err = write_to_file(target, encoded)
  if not ok then
    notify.error(("Failed to export favorites to '%s': %s"):format(target, tostring(err)))
    return false
  end

  notify.info(("Exported %d favorite(s) to '%s'"):format(#favs, target))
  return true
end

--- Import favorites from a JSON file (as produced by M.export or hand-
--- written), merging with the current list. Existing favorites are kept in
--- place; new ones are appended, deduplicated.
--- @param path string
--- @return boolean ok
function M.import(path)
  local target = vim.fn.expand(path)

  if not is_readable_file(target) then
    notify.error(("Cannot import: '%s' does not exist"):format(target))
    return false
  end

  local content = read_file(target)
  local ok_json, decoded = pcall(vim.fn.json_decode, content or "")
  if not ok_json or type(decoded) ~= "table" then
    notify.error(("Cannot import: '%s' is not valid JSON"):format(target))
    return false
  end

  local favs = M.load()
  local seen = {}
  local merged = {}

  for _, entry in ipairs(favs) do
    if type(entry) == "string" and not seen[entry] then
      seen[entry] = true
      table.insert(merged, entry)
    end
  end
  for _, entry in ipairs(decoded) do
    if type(entry) == "string" and not seen[entry] then
      seen[entry] = true
      table.insert(merged, entry)
    end
  end

  M.save(merged)
  notify.info(("Imported favorites from '%s' (%d total)"):format(target, #merged))
  return true
end

--- Check if a command is a favorite
--- @param cmd string
--- @return boolean
function M.is_favorite(cmd)
  local favs = M.load()
  for _, entry in ipairs(favs) do
    if entry == cmd then return true end
  end
  return false
end

return M
