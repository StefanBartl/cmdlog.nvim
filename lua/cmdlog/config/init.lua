---@module 'cmdlog.config'
--- Configuration handling for cmdlog: merges user options with DEFAULTS
--- and exposes the result as `M.options`. Never mutate `M.options` outside
--- of `M.setup()` — read it via `require("cmdlog.config").options.XYZ`.

local DEFAULTS = require("cmdlog.config.DEFAULTS")

local M = {}

---@type CmdlogConfig
M.options = vim.deepcopy(DEFAULTS)

--- What the last `setup()` had to ignore, for `:checkhealth`. Reset on
--- every call so issues from an earlier setup() never linger.
---@type string[]
local issues = {}

--- Keys `setup()` accepts. A nested table names that option's own accepted
--- keys (validated the same way, one level deep); `true` accepts any value
--- without descending into it -- `keymaps` is itself keyed by arbitrary
--- `:Cmdlog` subcommand names, and `redact_patterns`/`risky_patterns` are
--- `string[]|false`, not option tables.
---@type table<string, true|table<string, true>>
local KNOWN = {
  picker = true,
  favorites_path = true,
  shell_history_path = true,
  favorite_tags_path = true,
  project_history_path = true,
  stats_path = true,
  errors_path = true,
  track_commands = true,
  redact_patterns = true,
  extra_files = { history = true, all = true },
  project_scoped = { enabled = true },
  mappings = {
    enabled = true,
    select = true,
    toggle_favorite = true,
    refresh = true,
    delete = true,
    toggle_selection = true,
    tag = true,
    cycle_source = true,
    undo_favorite = true,
    move_favorite_up = true,
    move_favorite_down = true,
    lazygit = true,
  },
  keymaps = true,
  shell_history = { parse = true, matches = true },
  preview_execute = true,
  highlight_risky = true,
  risky_patterns = true,
}

--- Values accepted for a `KNOWN` key whose *type* alone isn't restrictive
--- enough. `picker` is a plain string as far as `KNOWN` is concerned, but
--- only three are meaningful; anything else must degrade to
--- `DEFAULTS.picker` before the merge (ERR-22) -- `open_picker()` routes
--- only `"telescope"`/`"fzf"`/`"fzf-lua"` to a real backend, and a typo
--- reaching `M.options` as-is falls through to the Telescope branch, which
--- throws "module 'telescope.pickers' not found" on every `:Cmdlog`
--- subcommand on a setup that does not have Telescope installed.
---@type table<string, table<string, true>>
local ENUM_VALUES = {
  picker = { telescope = true, fzf = true, ["fzf-lua"] = true },
}

---@internal
---`key` with the nearest known one as a hint when there is a plausible one.
---@param key any
---@param known table<string, any>
---@param prefix string
---@return string
local function describe_unknown(key, known, prefix)
  local levenshtein = require("lib.lua.strings.distance").levenshtein
  local name = tostring(key)
  local best, best_distance = nil, nil
  for candidate in pairs(known) do
    local d = levenshtein(name, candidate)
    if d <= 3 and (best_distance == nil or d < best_distance) then
      best, best_distance = candidate, d
    end
  end
  if best then
    return string.format("unknown option '%s%s' (did you mean '%s%s'?)", prefix, name, prefix, best)
  end
  return string.format("unknown option '%s%s'", prefix, name)
end

---@internal
---Drop what cannot be merged, and say so. A misspelled key would otherwise
---land in `M.options` as a dead field with the default still silently in
---force; a non-table value for a nested option table (`mappings = false`)
---would replace the whole table instead of degrading to its default.
---@param user_opts table
---@return table clean  the accepted subset, nested option tables filtered
---@return string[] found_issues
local function sanitize(user_opts)
  local clean, found_issues = {}, {}
  for key, value in pairs(user_opts) do
    local known = KNOWN[key]
    if known == nil then
      found_issues[#found_issues + 1] = describe_unknown(key, KNOWN, "")
    elseif type(known) == "table" then
      if type(value) ~= "table" then
        found_issues[#found_issues + 1] = string.format(
          "option '%s' must be a table, got %s -- using the default",
          key,
          type(value)
        )
      else
        local nested = {}
        for sub_key, sub_value in pairs(value) do
          if known[sub_key] then
            nested[sub_key] = sub_value
          else
            found_issues[#found_issues + 1] = describe_unknown(sub_key, known, key .. ".")
          end
        end
        clean[key] = nested
      end
    else
      local enum = ENUM_VALUES[key]
      if enum and not enum[value] then
        found_issues[#found_issues + 1] =
          string.format("invalid value for '%s': %s -- using the default", key, vim.inspect(value))
      else
        clean[key] = value
      end
    end
  end
  table.sort(found_issues)
  return clean, found_issues
end

--- Merges `opts` over DEFAULTS into `M.options`.
---
--- Options are validated before the merge (ERR-50): an unknown key -- top
--- level, or inside `extra_files`, `project_scoped`, `mappings`, or
--- `shell_history` -- is dropped with a did-you-mean hint instead of
--- silently surviving the merge as a dead field with the default still in
--- force; a non-table value for one of those four falls back to its
--- default rather than replacing the whole table. A known key with a value
--- outside its accepted range -- currently just `picker` -- likewise
--- degrades to its default instead of reaching `M.options` as-is (ERR-22).
--- All three are reported here and again by `:checkhealth cmdlog` (see
--- `M.issues()`).
---@param opts table|nil
---@return nil
function M.setup(opts)
  opts = opts or {}
  local clean, found_issues = sanitize(opts)
  issues = found_issues
  if #issues > 0 then
    require("lib.nvim.notify.safe")
      .create_safe("[cmdlog.nvim.config]")
      .warn("ignored config: " .. table.concat(issues, "; "))
  end

  M.options = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), clean)
end

--- What the last `setup()` ignored: unknown keys, option tables of the
--- wrong type, and out-of-range values, one human-readable line each. Empty
--- when everything was accepted.
---@return string[]
function M.issues()
  return vim.list_extend({}, issues)
end

return M
