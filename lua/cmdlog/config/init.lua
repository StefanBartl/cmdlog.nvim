---@module 'cmdlog.config'
--- Configuration of cmdlog: `DEFAULTS` plus what the user gave, merged by
--- `lib.lua.config.new` (a fresh copy of the defaults on every `setup()`, unknown
--- keys and wrong types reported before the merge, ERR-50 / ERR-22) and
--- exposed as `M.options`. Never write into `M.options` -- read it via
--- `require("cmdlog.config").options.XYZ`.

local DEFAULTS = require("cmdlog.config.DEFAULTS")

local M = {}

--- What the schema inferred from `DEFAULTS` cannot say:
---  * `picker` has three meaningful values; anything else must degrade to the
---    default (`open_picker()` routes only these to a real backend, and a typo
---    would fall through to the Telescope branch and throw on a setup without it);
---  * `redact_patterns` / `risky_patterns` are `string[]|false`;
---  * `shell_history` is empty in the defaults but takes the two escape hatches;
---  * a picker key may be `false` to unbind it.
---@type table<string, string|table>
local SCHEMA = {
  picker = { "string", enum = { "telescope", "fzf", "fzf-lua" } },
  redact_patterns = "table|false",
  risky_patterns = "table|false",
  shell_history = { "table", fields = { parse = "function", matches = "function" } },
}
for key, default in pairs(DEFAULTS.mappings) do
  if type(default) == "string" then SCHEMA["mappings." .. key] = "string|false" end
end

local cfg = require("lib.lua.config").new(DEFAULTS, {
  name = "cmdlog",
  schema = SCHEMA,
  notify = function(message)
    require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.config]").warn(message)
  end,
  on_change = function(current)
    M.options = current
  end,
})

---@type CmdlogConfig
M.options = cfg.get()

--- Sets the options. Every call starts from `DEFAULTS`; unknown keys (top
--- level, or inside `extra_files`, `project_scoped`, `mappings`,
--- `shell_history`), option tables of the wrong type and values outside their
--- range (`picker`) are dropped with a hint, reported here and again by
--- `:checkhealth cmdlog` (see `M.issues()`).
---@param opts table|nil
---@return nil
function M.setup(opts)
  cfg.setup(opts)
end

--- What the last `setup()` ignored: unknown keys, option tables of the
--- wrong type, and out-of-range values, one human-readable line each. Empty
--- when everything was accepted.
---@return string[]
function M.issues()
  return cfg.issues()
end

return M
