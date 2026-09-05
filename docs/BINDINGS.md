# Bindings Cheatsheet

Single reference for every user command, in-picker keymap and autocmd that
`cmdlog.nvim` registers. The source of truth lives in
[`lua/cmdlog/bindings/`](../lua/cmdlog/bindings/) — this file documents it in
prose. Inspect it at runtime (plugin must be loaded) with:

```
:lua vim.print(require("cmdlog.bindings").catalog())
```

## User commands

Registered in [`lua/cmdlog/bindings/usrcmds.lua`](../lua/cmdlog/bindings/usrcmds.lua)
as a single `:Cmdlog [subcommand]` verb, built via
`lib.nvim.bindings.usercmd.composer` with `<Tab>` completion on the subcommand.

| Command                 | Description                                                                  |
| ------------------------ | ---------------------------------------------------------------------------- |
| `:Cmdlog`               | Combines favorites and history, showing only unique commands (no duplicates) |
| `:Cmdlog full`          | Combines favorites and full history, allowing duplicates                     |
| `:Cmdlog nvim`          | Shows only unique Neovim (`:`) commands (latest occurrence kept)             |
| `:Cmdlog nvim-full`     | Shows full Neovim (`:`) history, including duplicates                        |
| `:Cmdlog shell`         | Shows unique shell history (latest occurrence kept)                          |
| `:Cmdlog shell-full`    | Shows full shell history, including duplicates                               |
| `:Cmdlog favorites`     | Shows commands you've marked as favorites                                    |
| `:Cmdlog project`       | Shows command history recorded for the current Git project, deduplicated     |
| `:Cmdlog lua`           | Shows only Lua-mode command history, deduplicated                            |
| `:Cmdlog stats`         | Shows commands sorted by usage frequency                                     |
| `:Cmdlog risky test <command>` | Reports which `risky_patterns` match a given command line             |
| `:Cmdlog export [path]` | Exports favorites to a JSON file (default: favorites path + `.export.json`)  |
| `:Cmdlog import path`   | Imports favorites from a JSON file, merged with the current list             |

`risky test`, `export` and `import` are registered directly in
[`lua/cmdlog/bindings/usrcmds.lua`](../lua/cmdlog/bindings/usrcmds.lua)'s
`M.register()`, not in `M.catalog` — each takes an argument, unlike every
catalog entry's zero-arg picker function, so they have no normal-mode
entry-point keymap via `keymaps`. `risky test` deliberately declares no `args`
spec either: what it takes is a whole command line, not a positional token.

## Picker keymaps

Implemented in [`lua/cmdlog/ui/mappings.lua`](../lua/cmdlog/ui/mappings.lua)
(catalog mirrored in [`lua/cmdlog/bindings/picker_mappings.lua`](../lua/cmdlog/bindings/picker_mappings.lua))
and applied inside every picker (Telescope insert mode). All are
user-configurable via `setup({ mappings = { ... } })` — see
[configuration.md](./configuration.md). Set a value to `false` to disable it, or
`mappings.enabled = false` to disable all of them at once. A legend of
the active ones (generated from `config.options.mappings`, not hardcoded)
also shows in the Telescope prompt title.

**Telescope only, and the table below is the whole story.** These keys are
handed to Telescope through a picker's `attach_mappings`, which
[`ui/picker_utils.lua`](../lua/cmdlog/ui/picker_utils.lua)'s fzf-lua branch
does not pass on. Under `picker = "fzf"` exactly one action is bound —
`default` (`<CR>`), which *runs* the selected command rather than inserting
it. No favorite toggle, no tag, no delete, in any picker.

| Default | Config key        | Action                                            |
| ------- | ------------------ | -------------------------------------------------- |
| `<CR>`    | `mappings.select`          | Insert the selected command into the cmdline (no execution) |
| `<Tab>`   | `mappings.toggle_favorite` | Toggle favorite status for the selected command   |
| `<C-r>`   | `mappings.refresh`         | Refresh the current picker                        |
| `<C-x>`   | `mappings.delete`          | Delete the selected entry — or every marked one — from its underlying history (Neovim `:` history or the shell history file) |
| `<C-Space>` | `mappings.toggle_selection` | Mark/unmark an entry for a batch delete, then move down |
| `<C-t>`   | `mappings.tag`             | Tag the selected favorite (favorites picker only) |
| `<C-s>`   | `mappings.cycle_source`    | Rotate to the next picker (nvim → shell → favorites → project → …), keeping the current prompt text. Telescope only ([`ui/cycle.lua`](../lua/cmdlog/ui/cycle.lua)) |
| `<C-z>`   | `mappings.undo_favorite`   | Undo the most recent favorite toggle (single-level) |
| `<C-Up>`  | `mappings.move_favorite_up`   | Move the selected favorite up one slot (favorites picker only) |
| `<C-Down>`| `mappings.move_favorite_down` | Move the selected favorite down one slot (favorites picker only) |

## Optional entry-point keymaps (which-key aware)

Registered in [`lua/cmdlog/bindings/keymaps.lua`](../lua/cmdlog/bindings/keymaps.lua). Disabled
by default — the plugin never claims a leader key on its own. Configured as a
map of subcommand name to lhs, with `""` meaning bare `:Cmdlog`:

```lua
require("cmdlog").setup({
  keymaps = { [""] = "<leader>ch", favorites = "<leader>cf" },
})
```

The catalog is derived from [`lua/cmdlog/bindings/usrcmds.lua`](../lua/cmdlog/bindings/usrcmds.lua),
so every subcommand there is mappable by name. Every registered keymap
carries a `desc`, so [which-key.nvim](https://github.com/folke/which-key.nvim)
(v3+) shows it automatically — no extra which-key registration needed.

| Config key            | Command                |
| ---------------------- | ----------------------- |
| `keymaps[""]`          | `:Cmdlog`               |
| `keymaps.full`         | `:Cmdlog full`          |
| `keymaps.nvim`         | `:Cmdlog nvim`          |
| `keymaps["nvim-full"]` | `:Cmdlog nvim-full`     |
| `keymaps.shell`        | `:Cmdlog shell`         |
| `keymaps["shell-full"]`| `:Cmdlog shell-full`    |
| `keymaps.favorites`    | `:Cmdlog favorites`     |
| `keymaps.project`      | `:Cmdlog project`       |
| `keymaps.lua`          | `:Cmdlog lua`           |
| `keymaps.stats`        | `:Cmdlog stats`         |

## Autocmds

One, and only when `track_commands` is on (it is by default):

| Event | Group | Purpose |
| ------ | ------ | -------- |
| `CmdlineLeave` | `cmdlog_tracker` | Record every executed `:` command into project history, usage stats and the error log |

Registered by [`lua/cmdlog/core/tracker.lua`](../lua/cmdlog/core/tracker.lua),
described in [`lua/cmdlog/bindings/autocmds.lua`](../lua/cmdlog/bindings/autocmds.lua).
It ignores aborted and empty cmdlines and anything matching `redact_patterns`,
and defers the actual writes with `vim.schedule` so a `:` command never waits
on a disk write. `track_commands = false` skips the autocmd entirely.
