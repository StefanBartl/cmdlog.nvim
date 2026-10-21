---@module 'cmdlog.ui.confirm'
--- Yes/no question for the delete confirmations, answered through lib.nvim's
--- `ui.kit.ask`: it waits for a dialog that is already open instead of
--- replacing it (which would drop that dialog's answer), and anything that is
--- not an explicit yes -- no answer in ten minutes, a dialog that cannot open --
--- is a "no", so a delete never goes ahead by accident. When the float cannot
--- open at all, `ask` falls back to `vim.ui.select`.
---
--- Contract: `{ question, on_answer(yes: boolean) }`, `on_answer` at most once.

local M = {}

---@param opts { question: string, on_answer: fun(yes: boolean) }
---@return nil
function M.ask(opts)
  require("lib.nvim.ui.kit").ask(opts)
end

return M
