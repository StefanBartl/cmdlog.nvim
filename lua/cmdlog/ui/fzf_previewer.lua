---@module 'cmdlog.ui.fzf_previewer'
--- Text-returning previewer for fzf-lua pickers.

local common = require("cmdlog.ui.preview_utils.common")
local cmp_preview = require("cmdlog.ui.preview_utils.compute_preview_text")

local M = {}

-- ---------------------------------------------------------------------------
-- main previewer (patched branch inserted as requested)
-- ---------------------------------------------------------------------------

---@nodiscard
---@return fun(entry:any, ctx:any):string
function M.command_previewer()
  return function(entry, _)
    local raw = common.to_s(entry)
    return cmp_preview(raw, {})
  end
end

return M
