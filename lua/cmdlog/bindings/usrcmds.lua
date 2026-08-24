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
---@internal
---@param entry { module: string, fn: string }
---@return fun()
local function handler(entry)
  return function()
    require(entry.module)[entry.fn]()
  end
end

--- Registers `:Cmdlog` and every subcommand in `M.catalog`, plus two
--- routes not in the catalog (`export`/`import`): those take an argument,
--- unlike every catalog entry's zero-arg picker function, so they're kept
--- out of `M.catalog` -- which `bindings.keymaps` also reads to build
--- zero-arg entry-point keymaps -- rather than special-cased there.
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

  routes[#routes + 1] = {
    path = { "risky", "test" },
    desc = "Show which risky_patterns match a command (tune the list without guessing)",
    -- Deliberately no `args` spec: the thing being tested is a whole command
    -- line ("git reset --hard HEAD~1"), not a positional token. Declaring a
    -- positional would eat "git" into ctx.args and leave the rest behind, and
    -- quoting the command just to pass it through defeats the purpose.
    run = function(ctx)
      require("cmdlog.ui.risky_test").report(table.concat(ctx.rest or {}, " "))
    end,
  }

  routes[#routes + 1] = {
    path = { "export" },
    desc = "Export favorites to a JSON file (default: favorites path + .export.json)",
    args = { { name = "path", type = "PATH", optional = true } },
    run = function(ctx)
      require("cmdlog.core.favorites").export(ctx.args.path)
    end,
  }

  routes[#routes + 1] = {
    path = { "import" },
    desc = "Import favorites from a JSON file, merging with the current list",
    args = { { name = "path", type = "PATH" } },
    run = function(ctx)
      require("cmdlog.core.favorites").import(ctx.args.path)
    end,
  }

  composer.verb("Cmdlog", {
    desc = "Command history pickers",
    default = default_run,
    routes = routes,
  })
end

return M
