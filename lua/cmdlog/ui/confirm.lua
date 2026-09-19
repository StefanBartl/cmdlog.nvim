---@module 'cmdlog.ui.confirm'
--- Soft dependency on ui.nvim's `ui.kit.confirm` dialog.
---
--- docs/installation.md documents ui.nvim as optional, so a missing ui.nvim
--- must not turn a delete into a hard crash/traceback (LUA-01): `M.ask`
--- prefers `ui.kit.confirm` when ui.nvim is installed and otherwise falls
--- back to Neovim's own `vim.fn.confirm()`, answering the exact same
--- `{ question, on_answer(yes: boolean) }` contract either way (see
--- ui.nvim's lua/ui/kit/confirm.lua "Answer contract" -- the default two-
--- choice dialog resolves to a boolean, Yes == true) -- callers never need
--- to know which backend actually answered.

local M = {}

--- Ask a yes/no question, preferring ui.kit's dialog and falling back to
--- `vim.fn.confirm()` when ui.nvim isn't installed. `vim.fn.confirm()`
--- answers synchronously, but `on_answer` still fires exactly once either
--- way, so callers can treat this as async in both cases.
---@param opts { question: string, on_answer: fun(yes: boolean) }
---@return nil
function M.ask(opts)
  local ok_kit, kit = pcall(require, "ui.kit")
  if ok_kit then
    kit.confirm(opts)
    return
  end

  local choice = vim.fn.confirm(opts.question or "", "&Yes\n&No", 2)
  if opts.on_answer then opts.on_answer(choice == 1) end
end

return M
