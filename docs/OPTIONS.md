# Options Workflow for cmdlog.nvim

This document describes how configuration options are structured, merged, and accessed within the `cmdlog.nvim` plugin.

## Overview

- All default options are stored centrally in a table called `default_config`.
- When a user calls `setup({ ... })`, their configuration is merged with the defaults.
- The merged configuration is available globally via `M.options`.
- No option is mandatory for the user to set; defaults are always applied automatically.

---

## How Configuration Works

### Default Options

Defaults are defined once in `lua/cmdlog/config/DEFAULTS.lua` like this:

```lua
local DEFAULTS = {
  favorites_path = vim.fn.stdpath("data") .. "/cmdlog/favorites.json",
  picker = "telescope", -- or "fzf"
  shell_history_path = "default", -- or custom shell history file path

  favorite_tags_path = vim.fn.stdpath("data") .. "/cmdlog/favorite_tags.json",
  project_history_path = vim.fn.stdpath("data") .. "/cmdlog/project_history.json",
  stats_path = vim.fn.stdpath("data") .. "/cmdlog/stats.json",
  errors_path = vim.fn.stdpath("data") .. "/cmdlog/errors.json",

  track_commands = true, -- record ':' commands for project history, stats, error tracking
  redact_patterns = { "password", "secret", "token", "Bearer", "api[-_]?key" }, -- never recorded
  extra_files = { history = {}, all = {} }, -- extra read-only command files folded into pickers
  keymaps = {}, -- { [""] = "<leader>ch", favorites = "<leader>cf", ... }

  mappings = {
    enabled = true,
    select = "<CR>",          -- insert selected command into the cmdline
    toggle_favorite = "<Tab>", -- mark/unmark the selected command as favorite
    refresh = "<C-r>",        -- refresh the current picker
    delete = "<C-x>",         -- delete the selected entry from its underlying history
    tag = "<C-t>",            -- tag the selected favorite (favorites picker only)
    cycle_source = "<C-s>",   -- rotate to the next picker, keeping the current prompt text
    undo_favorite = "<C-z>",  -- undo the most recent favorite toggle
    move_favorite_up = "<C-Up>",   -- move the selected favorite up (favorites picker only)
    move_favorite_down = "<C-Down>", -- move the selected favorite down (favorites picker only)
  },
  highlight_risky = true,
  risky_patterns = { "rm%s+%-rf", "git%s+reset%s+%-%-hard", --[[ ... ]] },
}
```

The plugin ensures that `M.options` (in `lua/cmdlog/config/init.lua`) is initialized with a deep copy of `DEFAULTS`.

Set any `mappings.*` entry to `false` to disable that keybinding, or to a different key string to remap it. Set `mappings.enabled = false` to disable all cmdlog-internal picker mappings at once.

`mappings.tag` only binds in the favorites picker: tags are stored per
favorite, so tagging a command that is not one has nothing to attach to.

### `keymaps`

Optional map of `:Cmdlog` subcommand name to a normal-mode `lhs`. Use `""`
for bare `:Cmdlog`. Registered via `vim.keymap.set` with a `desc`; also
passed to `which-key.nvim`'s `add()` when it is installed, so the
descriptions show up there too. See `lua/cmdlog/integrations/which_key.lua`.

An entry naming a subcommand that does not exist is skipped with a warning
rather than silently producing a dead keymap.

### Deleting history entries

`mappings.delete` (default `<C-x>`) removes the selected command from its
underlying history source:

- Neovim `:` command history — via `vim.fn.histdel()`. In-memory/shada only,
  no confirmation prompt.
- Shell history file — rewrites the file on disk after a `vim.fn.confirm()`
  prompt, since this touches a file outside of Neovim's own state.
- In the combined `:Cmdlog`/`:CmdlogFull` pickers, both sources are tried;
  whichever one(s) actually contain the command are updated.

Set `mappings.delete = false` to disable it.

### Project-based favorites (opt-in)

By default all favorites live in one global `favorites_path` file. Set
`project_scoped.enabled = true` to keep a separate favorites file per Git
project instead:

```lua
require("cmdlog").setup({
  project_scoped = { enabled = true },
})
```

When enabled, cmdlog looks for a `.git` directory upward from the current
working directory. If found, favorites are stored in
`<dir of favorites_path>/projects/<repo-name>-<hash>.json` instead of the
global file. Outside of a Git repo (or with `project_scoped.enabled = false`,
the default), the global `favorites_path` is used as before — existing
favorites are unaffected unless you opt in.

### `redact_patterns` (privacy filter)

Lua patterns (`string.find`, same shape as `risky_patterns`) checked in
`core/tracker.lua` before anything is written: a `:` command matching any
pattern is never recorded to project history, usage stats, or the error
log. This matters because those stores are plaintext JSON under
`stdpath("data")`, and e.g. `:!curl -H "Authorization: Bearer …"` would
otherwise persist the token there forever.

Default: `{ "password", "secret", "token", "Bearer", "api[-_]?key" }`. Set
to `false` (or `{}`) to disable.

### `extra_files`

Folds your own plain-text command files (one command per line) into the
pickers as additional read-only history sources — no favorites/tags/delete
support for these entries, just listed alongside Neovim/shell history:

```lua
require("cmdlog").setup({
  extra_files = {
    history = { "~/my_global_history.txt" },
    all = { "~/my_favs.txt" },
  },
})
```

`history` entries are folded into the Neovim-history-based pickers
(`:Cmdlog nvim`, `:Cmdlog nvim-full`) and the combined pickers (`:Cmdlog`,
`:Cmdlog full`); `all` entries only into the latter. In the combined
pickers, entries from either list are labelled `extra` — see the next
section.

### Origin labels in the combined pickers

`:Cmdlog` and `:Cmdlog full` show where each non-favorite entry came from
— `nvim`, `shell`, or `extra` (from `extra_files`) — next to the command,
via `picker_utils`' `opts.label` hook. Favorites are already distinguished
by the `★` marker and carry no origin label.

### `mappings.cycle_source`

Rotates the open picker to the next one in a fixed order (`nvim` → `shell`
→ `favorites` → `project` → back to `nvim`), carrying over whatever
prompt text was typed so far. Telescope only, for the same reason
decoration is Telescope-only (see `risky_patterns` below): fzf-lua entries
double as the value fed back to actions. Default `<C-s>`; set to `false`
to disable.

### Favorites: undo and manual reordering

`mappings.undo_favorite` (default `<C-z>`) reverts the most recent
`<Tab>` toggle — single-level, only the last toggle is remembered, and
only for the project/global favorites file it applied to.

`mappings.move_favorite_up`/`move_favorite_down` (default `<C-Up>`/
`<C-Down>`) swap the selected favorite's position in the persisted list
order. Only bound in the favorites picker, where display order is exactly
that persisted order (elsewhere, order is Telescope's own sort).

### Favorites export/import

`:Cmdlog export [path]` writes the current favorites list to a JSON file
(`path` defaults to the favorites file's own path with a `.export.json`
suffix); `:Cmdlog import path` reads one back and merges it with the
current list (existing favorites kept, new ones appended, deduplicated).
See `core/favorites.lua`'s `M.export`/`M.import`. Useful as a migration
path between machines, or a manual backup before a risky edit.

### Risky command highlighting

`risky_patterns` is a list of Lua patterns (`string.find`, not regex) matched
against every entry shown in a picker. A match is highlighted with the
`CmdlogRiskyCommand` highlight group (linked to `DiagnosticError` by default —
override it with `vim.api.nvim_set_hl(0, "CmdlogRiskyCommand", { ... })` after
`setup()`). Set `highlight_risky = false`, or `risky_patterns = {}`, to
disable it. Currently Telescope-only.

### Optional entry-point keymaps

`keymaps` (empty by default) lets you assign normal-mode keys that call
`:Cmdlog` and its subcommands directly, e.g.:

```lua
require("cmdlog").setup({
  keymaps = {
    [""] = "<leader>ch",
    favorites = "<leader>cf",
    project = "<leader>cp",
  },
})
```

Every entry is registered with a `desc`, so [which-key.nvim](https://github.com/folke/which-key.nvim)
picks it up automatically. See [BINDINGS.md](./BINDINGS.md) for the full list
of keys.

### `track_commands`

When `true` (default), every `:` command is recorded via a single
`CmdlineLeave` autocmd (`core/tracker.lua`), feeding `project_history`,
`stats` and `errors`. Set to `false` to disable all three and skip the
autocmd entirely.

The plugin ensures that `M.options` is initialized with a deep copy of `DEFAULTS`.

### User Setup

When the user calls:

```lua
require("cmdlog").setup({
  picker = "fzf",
})
```

internally the plugin merges:

- `default_config`
- and the user's `user_config`

using `vim.tbl_deep_extend("force", {}, default_config, user_config or {})`.

Any missing options are automatically filled with their defaults.

---

## Best Practices for Adding New Options

When introducing a new option:

1. **Always add it to `default_config`** with a sensible default value.
2. **Never modify `M.options` directly** outside of `setup()`.
3. **Access options only through `config.options.XYZ`** within the plugin code.
4. **Document the new option** with a brief comment in `default_config`.

Example:

```lua
local default_config = {
  preview_layout = "vertical", -- Layout of the previewer ("vertical" or "horizontal")
}
```

---

## Why This Approach?

- Ensures stability even if the user provides no configuration.
- Protects against missing or invalid fields (`nil`, `v:null`).
- Makes it easier to extend the plugin with new features.
- Keeps the internal state predictable and easy to debug.

---

## Notes

- Always validate critical options if they affect important plugin behavior (e.g., `picker` must be `"telescope"` or `"fzf"`).
- If necessary, fallback gracefully to defaults inside feature implementations.
- Do not rely on the presence of optional fields unless you have defined a clear default.

---

# Summary

| Principle | Rule |
|:----------|:-----|
| Default configuration | Stored in `default_config` |
| Merging user options | Handled in `setup()` |
| Accessing options | Only via `config.options.XYZ` |
| Adding new options | Add to `default_config` with sensible defaults |

---
