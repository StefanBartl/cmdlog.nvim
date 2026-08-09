---@module 'cmdlog.integrations.which_key'
--- Surfaces the `:Cmdlog` subcommand keymaps in which-key.nvim, when it is
--- installed. No-op otherwise.
---
--- The actual `vim.keymap.set` calls happen exactly once, in
--- cmdlog.bindings.keymaps.register() (via lib.nvim.map), which already
--- attaches a `desc` to every mapping -- which-key v3+ picks those up on
--- its own without any registration step. This module previously called
--- vim.keymap.set() a second time for the same lhs/rhs pairs, which was
--- redundant (bindings.keymaps.register() already ran first from
--- cmdlog.bindings.register()) and duplicated the description table that
--- cmdlog.bindings.keymaps.catalog() already derives from the usercommand
--- catalog. It now only builds which-key specs from that catalog and calls
--- wk.add() -- see cmdlog/init.lua for the call order.
local M = {}

--- Register which-key specs for `:Cmdlog <subcommand>` keymaps. No-op when
--- which-key.nvim is not installed.
---@param keymaps table<string, string> Map of subcommand (use "" for bare :Cmdlog) to lhs
---@return nil
function M.register(keymaps)
  local ok_wk, wk = pcall(require, "which-key")
  if not ok_wk then return end

  local catalog = require("cmdlog.bindings.keymaps").catalog()

  local specs = {}
  for subcommand, lhs in pairs(keymaps) do
    if type(lhs) == "string" and lhs ~= "" then
      local entry = catalog[subcommand]
      if entry then
        table.insert(specs, { lhs, "<cmd>" .. entry.cmd .. "<CR>", desc = entry.desc, mode = "n" })
      end
    end
  end

  if #specs > 0 then wk.add(specs) end
end

return M
