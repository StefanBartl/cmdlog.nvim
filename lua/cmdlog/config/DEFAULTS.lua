---@module 'cmdlog.config.DEFAULTS'
--- Central table of default option values for cmdlog.
--- Add new options here first, with a sensible default and a short comment.

---@type CmdlogConfig
local DEFAULTS = {
  picker = "telescope",
  favorites_path = vim.fn.stdpath("data") .. "/cmdlog/favorites.json",
  shell_history_path = "default",

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
    select = "<CR>",         -- insert selected command into the cmdline
    toggle_favorite = "<Tab>", -- mark/unmark the selected command as favorite
    refresh = "<C-r>",       -- refresh the current picker
    delete = "<C-x>",        -- delete the selected entry from its underlying history
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

  -- Optional normal-mode entry-point keymaps for the :Cmdlog* commands.
  -- Disabled by default so the plugin never claims a leader key on its own.
  -- Every key set here gets a `desc`, so which-key.nvim picks it up automatically.
  keymaps = {
    enabled = false,
    cmdlog = nil,             -- :Cmdlog
    cmdlog_full = nil,        -- :CmdlogFull
    favorites = nil,          -- :CmdlogFavorites
    nvim_history = nil,       -- :CmdlogNvim
    nvim_history_full = nil,  -- :CmdlogNvimFull
    shell_history = nil,      -- :CmdlogShell
    shell_history_full = nil, -- :CmdlogShellFull
  },
}

return DEFAULTS
