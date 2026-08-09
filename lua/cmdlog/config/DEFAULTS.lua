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

  -- Opt-in: keep a separate favorites.json per Git project instead of one
  -- global file. Disabled by default so existing setups keep their current
  -- (global) favorites untouched. When enabled, the project file lives next
  -- to `favorites_path`, in a `projects/` subdirectory, named after the
  -- detected Git root.
  project_scoped = {
    enabled = false,
  },

  notes = {
    enabled = true,
    dir = vim.fn.stdpath("data") .. "/cmdlog.nvim/notes",
    format = "markdown",
    width = 60,
    autosave = true,
    persist = true,
  },

  -- Keymaps used inside cmdlog pickers. Set a value to false to disable it.
  mappings = {
    enabled = true,
    select = "<CR>", -- insert selected command into the cmdline
    toggle_favorite = "<Tab>", -- mark/unmark the selected command as favorite
    refresh = "<C-r>", -- refresh the current picker
    delete = "<C-x>", -- delete the selected entry from its underlying history
    tag = "<C-t>", -- add a tag to the selected favorite (favorites picker only)
  },

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
