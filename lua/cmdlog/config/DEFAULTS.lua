---@module 'cmdlog.config.DEFAULTS'
--- Central table of default option values for cmdlog.
--- Add new options here first, with a sensible default and a short comment.

---@type CmdlogConfig
local DEFAULTS = {
  picker = "telescope",
  favorites_path = vim.fn.stdpath("data") .. "/cmdlog/favorites.json",
  shell_history_path = "default",

  -- State files for the tag / project-history / stats / error-tracking
  -- features. All live under the same `cmdlog/` data directory as
  -- `favorites_path` — these were introduced on `main` under the older
  -- `nvim-cmdlog/` name and are renamed here to match the rest of the
  -- plugin, which had already moved. Each is created on first write, so a
  -- setup that never used these features has nothing to migrate.
  favorite_tags_path = vim.fn.stdpath("data") .. "/cmdlog/favorite_tags.json",
  project_history_path = vim.fn.stdpath("data") .. "/cmdlog/project_history.json",
  stats_path = vim.fn.stdpath("data") .. "/cmdlog/stats.json",
  errors_path = vim.fn.stdpath("data") .. "/cmdlog/errors.json",

  -- Record every ':' command, feeding project history, usage stats and
  -- error tracking. Set false to disable all three at the source.
  track_commands = true,

  -- Commands matching any of these Lua patterns (`string.find`, same as
  -- `risky_patterns`) are never recorded by `core/tracker.lua` -- not to
  -- project history, not to stats, not to the error log. Security feature:
  -- those files live in plaintext under stdpath("data"), and e.g.
  -- `:!curl -H "Authorization: Bearer …"` would otherwise persist the
  -- token there forever. Set to `false` (or an empty table) to disable.
  redact_patterns = {
    "password",
    "secret",
    "token",
    "Bearer",
    "api[-_]?key",
  },

  -- Extra plain-text command files folded in as additional read-only
  -- history sources (one command per line, no favorites/delete support).
  -- `history` entries are combined into the Neovim-history-based pickers
  -- (`nvim`, `nvim-full`) and the combined `:Cmdlog`/`:Cmdlog full` pickers;
  -- `all` entries are combined only into the latter.
  --
  --   extra_files = { history = { "~/my_global_history.txt" }, all = { "~/my_favs.txt" } }
  extra_files = {
    history = {},
    all = {},
  },

  -- Opt-in: keep a separate favorites.json per Git project instead of one
  -- global file. Disabled by default so existing setups keep their current
  -- (global) favorites untouched. When enabled, the project file lives next
  -- to `favorites_path`, in a `projects/` subdirectory, named after the
  -- detected Git root.
  project_scoped = {
    enabled = false,
  },

  -- Keymaps used inside cmdlog pickers. Set a value to false to disable it.
  mappings = {
    enabled = true,
    select = "<CR>", -- insert selected command into the cmdline
    toggle_favorite = "<Tab>", -- mark/unmark the selected command as favorite
    refresh = "<C-r>", -- refresh the current picker
    delete = "<C-x>", -- delete the selected entry, or every marked one, from its underlying history
    toggle_selection = "<C-Space>", -- mark/unmark an entry for a batch delete, then move down
    tag = "<C-t>", -- add a tag to the selected favorite (favorites picker only)
    cycle_source = "<C-s>", -- rotate to the next picker (nvim -> shell -> favorites -> project -> …), keeping the current prompt text
    undo_favorite = "<C-z>", -- undo the most recent favorite toggle
    move_favorite_up = "<C-Up>", -- move the selected favorite one slot up (favorites picker only)
    move_favorite_down = "<C-Down>", -- move the selected favorite one slot down (favorites picker only)
  },

  -- Escape hatch for a shell-history format the built-in parsers don't know
  -- (a custom HISTTIMEFORMAT, a wrapper that rewrites the file, a shell not
  -- covered at all). Both halves belong together:
  --
  --   parse(lines, shell) -> string[]   turn raw file lines into commands
  --   matches(line, cmd)  -> boolean    does this raw line hold that command
  --
  -- `matches` is what deleting needs, and setting `parse` without it makes
  -- `:Cmdlog` refuse to delete rather than let the built-in matcher guess --
  -- deleting rewrites the history file, and a wrong guess removes the wrong
  -- lines. Leave the table empty to use the built-in per-shell parsers.
  shell_history = {
    -- parse = function(lines, shell) ... end,
    -- matches = function(line, cmd) ... end,
  },

  -- Whether a picker's preview may *run* a history entry.
  --
  -- Off, because previewing is a browse action and the entries are not
  -- necessarily the user's own: `extra_files` folds arbitrary plain-text
  -- files in as history sources, and shell history is folded in too. With
  -- this on, moving the cursor onto `:!<cmd>` in the picker runs it, onto
  -- `:lua <expr>` evaluates it, onto `:term <cmd>` spawns it.
  --
  -- Even when enabled, an entry matching `risky_patterns` is never run --
  -- that list exists to name the commands whose whole problem is running
  -- them again -- and an argument carrying a `|`, a quote or a shell
  -- metacharacter is refused, because the previewers interpolate it into a
  -- command string.
  --
  -- `:edit <file>` previews the file either way: reading is not running.
  preview_execute = false,

  -- Highlight commands that are prone to causing damage or data loss.
  -- `risky_patterns` are plain Lua patterns matched against each command;
  -- set to `false` (or an empty table) to disable highlighting entirely.
  highlight_risky = true,
  risky_patterns = {
    "rm%s+%-rf",
    "git%s+reset%s+%-%-hard",
    "git%s+push.-%-%-force",
    "git%s+clean%s+%-[fd]",
    "%%bd!",
    "qa!",
    "wqa!",
    "sudo%s+rm",
    "mkfs",
    "dd%s+if=",
  },

  -- Optional normal-mode entry-point keymaps, as a map of
  -- `:Cmdlog` subcommand -> lhs. Use "" for bare `:Cmdlog`. Empty by
  -- default, so the plugin never claims a leader key on its own. Every key
  -- registered here carries a `desc`, so which-key.nvim picks it up
  -- automatically.
  --
  --   keymaps = { [""] = "<leader>hc", favorites = "<leader>hf" }
  --
  -- This replaced a fixed table keyed by the old flat command names
  -- (cmdlog_full, nvim_history, …) when those were migrated to
  -- `:Cmdlog <subcommand>`; a subcommand map stays correct as routes are
  -- added, which the fixed table did not.
  keymaps = {},
}

return DEFAULTS
