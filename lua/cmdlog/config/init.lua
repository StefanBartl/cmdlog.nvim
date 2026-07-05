---@module 'cmdlog.config'
--- Configuration handling for cmdlog: merges user options with DEFAULTS
--- and exposes the result as `M.options`. Never mutate `M.options` outside
--- of `M.setup()` — read it via `require("cmdlog.config").options.XYZ`.

local DEFAULTS = require("cmdlog.config.DEFAULTS")

local M = {}

---@type CmdlogConfig
M.options = vim.deepcopy(DEFAULTS)

---@param opts table|nil
function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), opts)

  local notes = M.options.notes
  if type(notes) ~= "table" then
    ---@diagnostic disable-next-line missing-fields
    notes = { enabled = false }
  end

  if notes.format ~= "markdown" then
    notes.format = "text"
  end

  if notes.dir == "" then
    notes.dir = DEFAULTS.notes.dir
  end

  if type(notes.width) ~= "number" then
    notes.width = DEFAULTS.notes.width
  end

  M.options.notes = notes

  ---@diagnostic disable-next-line inject-field
  M.options.mappings = type(M.options.mappings) == "table"
    and M.options.mappings
    or vim.deepcopy(DEFAULTS.mappings)
end

return M
