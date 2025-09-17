---@module 'cmdlog.ui.telescope_previewer'
---@brief Text-returning previewer for Telescope (feature-parity with fzf previewer).
---@description
--- Single buffer previewer that computes text synchronously and writes lines safely.

local previewers = require("telescope.previewers")
local api        = vim.api
local common     = require("cmdlog.ui.preview_utils.common")
local cpt_preview     = require("cmdlog.ui.preview_utils.compute_preview_text")

local M = {}

---@param self table
---@param text string|nil
local function set_preview_text(self, text)
  if not (self and self.state and self.state.bufnr) then return end
  local bufnr = self.state.bufnr
  if not api.nvim_buf_is_valid(bufnr) then return end
  local lines = vim.split(text or "", "\n", { plain = true })
  api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

--- Returns a Telescope buffer previewer with the same logic as the fzf previewer.
---@return table
function M.command_previewer()
  return previewers.new_buffer_previewer({
    define_preview = function(self, entry, _)
      local raw = common.to_s(entry and entry.value or entry)
      local text = cpt_preview(raw, {})
      set_preview_text(self, text)
    end,
  })
end

return M
