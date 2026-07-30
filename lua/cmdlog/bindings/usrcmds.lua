---@module 'cmdlog.bindings.usrcmds'
--- Single source of truth for the `:Cmdlog` user command and its subcommands.
---
--- Two changes met here. The command surface moved from seven flat
--- `:CmdlogX` commands to one `:Cmdlog <subcommand>` verb built on
--- lib.nvim.usercmd.composer; and its registration site moved out of
--- `lua/cmdlog/ui/picker.lua` into this bindings/ module, so
--- docs/BINDINGS.md and the code cannot drift apart.
---
--- `M.catalog` stays the machine-readable description (consumed by
--- `cmdlog.bindings.catalog()` and the docs), while `M.register()` feeds it
--- to composer. Adding a subcommand means adding one entry to `M.catalog`.

local M = {}

--- Every `:Cmdlog` subcommand. `path` is the token the user types; the entry
--- with `path = nil` is the bare `:Cmdlog` default.
---@type { path: string|nil, desc: string, module: string, fn: string }[]
M.catalog = {
  {
    path = nil,
    desc = "Favorites and history combined, deduplicated (bare :Cmdlog)",
    module = "cmdlog.ui.all_unique_picker",
    fn = "show_all_unique_picker",
  },
  {
    path = "full",
    desc = "All commands, including duplicates",
    module = "cmdlog.ui.all_picker",
    fn = "show_all_picker",
  },
  {
    path = "nvim",
    desc = "Neovim command-line history, deduplicated",
    module = "cmdlog.ui.history_unique_picker",
    fn = "show_history_unique_picker",
  },
  {
    path = "nvim-full",
    desc = "Neovim command-line history, including duplicates",
    module = "cmdlog.ui.history_picker",
    fn = "show_history_picker",
  },
  {
    path = "shell",
    desc = "Shell command history, deduplicated",
    module = "cmdlog.ui.shell_unique_picker",
    fn = "show_shell_unique_picker",
  },
  {
    path = "shell-full",
    desc = "Shell command history, including duplicates",
    module = "cmdlog.ui.shell_picker",
    fn = "show_shell_picker",
  },
  {
    path = "favorites",
    desc = "Favorited commands",
    module = "cmdlog.ui.favorites_picker",
    fn = "show_favorites_picker",
  },
  {
    path = "project",
    desc = "Command history for the current Git project",
    module = "cmdlog.ui.project_picker",
    fn = "show_project_picker",
  },
  {
    path = "lua",
    desc = "Lua-mode command history, deduplicated",
    module = "cmdlog.ui.lua_picker",
    fn = "show_lua_picker",
  },
  {
    path = "stats",
    desc = "Commands sorted by usage frequency",
    module = "cmdlog.ui.stats_picker",
    fn = "show_stats_picker",
  },
}

--- Resolve a catalog entry to its picker function, requiring the module only
--- when the subcommand actually runs — registration itself pulls in no
--- picker modules, and so costs nothing at startup.
---@param entry { module: string, fn: string }
---@return fun()
local function handler(entry)
  return function()
    require(entry.module)[entry.fn]()
  end
end

--- Registers `:Cmdlog` and every subcommand in `M.catalog`.
---@return nil
function M.register()
  local composer = require("lib.nvim.usercmd.composer")

  local default_run, routes = nil, {}
  for _, entry in ipairs(M.catalog) do
    if entry.path == nil then
      default_run = handler(entry)
    else
      routes[#routes + 1] = {
        path = { entry.path },
        desc = entry.desc,
        run = handler(entry),
      }
    end
  end

  composer.verb("Cmdlog", {
    desc = "Command history pickers",
    default = default_run,
    routes = routes,
  })
end

return M
