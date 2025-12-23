---@module 'cmdlog.config'
--- Configuration handling for cmdlog.

local M = {}

---@type CmdlogConfig
M.options = {
  picker = "telescope",
  favorites_path = vim.fn.stdpath("data") .. "/cmdlog/favorites.json",
  shell_history_path = "default",

  notes = {
    enabled = true,
    dir = vim.fn.stdpath("data") .. "/nvim-cmdlog/notes",
    format = "markdown",
    width = 60,
    autosave = true,
    persist = true,
  },
}

---@param opts table|nil
function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", M.options, opts)

  local notes = M.options.notes
  if type(notes) ~= "table" then
    notes = { enabled = false }
  end

  if notes.format ~= "markdown" then
    notes.format = "text"
  end

  if notes.dir == "" then
    notes.dir = vim.fn.stdpath("data") .. "/nvim-cmdlog/notes"
  end

  if type(notes.width) ~= "number" then
    notes.width = 60
  end

  M.options.notes = notes
end

return M
