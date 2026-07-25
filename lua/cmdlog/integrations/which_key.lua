---@module 'cmdlog.integrations.which_key'
--- Registers user-chosen keymaps for `:Cmdlog` subcommands, with
--- descriptions surfaced through which-key.nvim when it is installed.
--- Falls back to plain vim.keymap.set (still with a `desc`, which
--- which-key would also pick up automatically) when which-key is absent.
local M = {}

---@type table<string, string>
local descriptions = {
  [""] = "Cmdlog: favorites + history (unique)",
  favorites = "Cmdlog: favorites",
  full = "Cmdlog: favorites + full history",
  nvim = "Cmdlog: Neovim history (unique)",
  ["nvim-full"] = "Cmdlog: Neovim history (full)",
  shell = "Cmdlog: shell history (unique)",
  ["shell-full"] = "Cmdlog: shell history (full)",
  project = "Cmdlog: project-local history",
  lua = "Cmdlog: Lua command history",
  stats = "Cmdlog: usage stats",
}

--- Register keymaps for `:Cmdlog <subcommand>`.
---@param keymaps table<string, string> Map of subcommand (use "" for bare :Cmdlog) to lhs
---@return nil
function M.register(keymaps)
  local ok_wk, wk = pcall(require, "which-key")

  local specs = {}
  for subcommand, lhs in pairs(keymaps) do
    if lhs and lhs ~= "" then
      local cmd = subcommand == "" and "Cmdlog" or ("Cmdlog " .. subcommand)
      local desc = descriptions[subcommand] or ("Cmdlog: " .. subcommand)

      vim.keymap.set("n", lhs, "<cmd>" .. cmd .. "<CR>", { desc = desc, silent = true })

      if ok_wk then
        table.insert(specs, { lhs, "<cmd>" .. cmd .. "<CR>", desc = desc, mode = "n" })
      end
    end
  end

  if ok_wk and #specs > 0 then
    wk.add(specs)
  end
end

return M
