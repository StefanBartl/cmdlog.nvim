---@module 'cmdlog.bindings.keymaps'
--- Optional normal-mode entry-point keymaps for the :Cmdlog* commands.
--- Every keymap set here carries a `desc`, so which-key.nvim (v3+) picks it
--- up automatically without any extra registration step.

local M = {}

---@type table<string, {cmd: string, desc: string}>
M.catalog = {
  cmdlog = { cmd = "Cmdlog", desc = "Cmdlog: history + favorites (unique)" },
  cmdlog_full = { cmd = "CmdlogFull", desc = "Cmdlog: history + favorites (full)" },
  favorites = { cmd = "CmdlogFavorites", desc = "Cmdlog: favorites" },
  nvim_history = { cmd = "CmdlogNvim", desc = "Cmdlog: Neovim command history (unique)" },
  nvim_history_full = { cmd = "CmdlogNvimFull", desc = "Cmdlog: Neovim command history (full)" },
  shell_history = { cmd = "CmdlogShell", desc = "Cmdlog: shell history (unique)" },
  shell_history_full = { cmd = "CmdlogShellFull", desc = "Cmdlog: shell history (full)" },
}

--- Registers the configured keymaps. No-op unless `config.options.keymaps.enabled`.
--- @return nil
function M.register()
  local keymaps = require("cmdlog.config").options.keymaps
  if not keymaps or not keymaps.enabled then
    return
  end

  for key, entry in pairs(M.catalog) do
    local lhs = keymaps[key]
    if type(lhs) == "string" and lhs ~= "" then
      vim.keymap.set("n", lhs, "<cmd>" .. entry.cmd .. "<CR>", {
        desc = entry.desc,
        silent = true,
      })
    end
  end
end

return M
