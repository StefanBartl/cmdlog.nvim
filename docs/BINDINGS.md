# Bindings Cheatsheet

Single reference for every user command, in-picker keymap and autocmd that
`cmdlog.nvim` registers. The source of truth lives in
[`lua/cmdlog/bindings/`](../lua/cmdlog/bindings/) — this file documents it in
prose. Inspect it at runtime (plugin must be loaded) with:

```
:lua vim.print(require("cmdlog.bindings").catalog())
```

## User commands

Registered in [`lua/cmdlog/bindings/usrcmds.lua`](../lua/cmdlog/bindings/usrcmds.lua).

| Command            | Description                                                                  |
| ------------------ | ---------------------------------------------------------------------------- |
| `:CmdlogFavorites` | Shows commands you've marked as favorites                                    |
| `:Cmdlog`          | Combines favorites and history, showing only unique commands (no duplicates) |
| `:CmdlogFull`      | Combines favorites and full history, allowing duplicates                     |
| `:CmdlogNvim`      | Shows only unique Neovim (`:`) commands (latest occurrence kept)             |
| `:CmdlogNvimFull`  | Shows full Neovim (`:`) history, including duplicates                        |
| `:CmdlogShell`     | Shows unique shell history (latest occurrence kept)                          |
| `:CmdlogShellFull` | Shows full shell history, including duplicates                               |
| `:Cmdlog export [path]` | Exports favorites to a JSON file (default: favorites path + `.export.json`) |
| `:Cmdlog import path`   | Imports favorites from a JSON file, merged with the current list       |

`export`/`import` are registered directly in
[`lua/cmdlog/bindings/usrcmds.lua`](../lua/cmdlog/bindings/usrcmds.lua)'s
`M.register()`, not in `M.catalog` — they take a required/optional path
argument, unlike every catalog entry's zero-arg picker function, so they
have no normal-mode entry-point keymap via `keymaps`.

## Picker keymaps

Implemented in [`lua/cmdlog/ui/mappings.lua`](../lua/cmdlog/ui/mappings.lua)
(catalog mirrored in [`lua/cmdlog/bindings/picker_mappings.lua`](../lua/cmdlog/bindings/picker_mappings.lua))
and applied inside every picker (Telescope insert mode). All are
user-configurable via `setup({ mappings = { ... } })` — see
[OPTIONS.md](./OPTIONS.md). Set a value to `false` to disable it, or
`mappings.enabled = false` to disable all of them at once. A legend of
the active ones (generated from `config.options.mappings`, not hardcoded)
also shows in the Telescope prompt title.

| Default | Config key        | Action                                            |
| ------- | ------------------ | -------------------------------------------------- |
| `<CR>`    | `mappings.select`          | Insert the selected command into the cmdline (no execution) |
| `<Tab>`   | `mappings.toggle_favorite` | Toggle favorite status for the selected command   |
| `<C-r>`   | `mappings.refresh`         | Refresh the current picker                        |
| `<C-x>`   | `mappings.delete`          | Delete the selected entry from its underlying history (Neovim `:` history or the shell history file) |
| `<C-s>`   | `mappings.cycle_source`    | Rotate to the next picker (nvim → shell → favorites → project → …), keeping the current prompt text. Telescope only ([`ui/cycle.lua`](../lua/cmdlog/ui/cycle.lua)) |
| `<C-z>`   | `mappings.undo_favorite`   | Undo the most recent favorite toggle (single-level) |
| `<C-Up>`  | `mappings.move_favorite_up`   | Move the selected favorite up one slot (favorites picker only) |
| `<C-Down>`| `mappings.move_favorite_down` | Move the selected favorite down one slot (favorites picker only) |

## Optional entry-point keymaps (which-key aware)

Registered in [`lua/cmdlog/bindings/keymaps.lua`](../lua/cmdlog/bindings/keymaps.lua). Disabled
by default — the plugin never claims a leader key on its own. Enable and assign
keys via `setup({ keymaps = { enabled = true, cmdlog = "<leader>cl", ... } })`.
Every registered keymap carries a `desc`, so [which-key.nvim](https://github.com/folke/which-key.nvim)
(v3+) shows it automatically — no extra which-key registration needed.

| Config key            | Command             |
| ----------------------- | -------------------- |
| `keymaps.cmdlog`              | `:Cmdlog`          |
| `keymaps.cmdlog_full`         | `:CmdlogFull`      |
| `keymaps.favorites`           | `:CmdlogFavorites` |
| `keymaps.nvim_history`        | `:CmdlogNvim`      |
| `keymaps.nvim_history_full`   | `:CmdlogNvimFull`  |
| `keymaps.shell_history`       | `:CmdlogShell`     |
| `keymaps.shell_history_full`  | `:CmdlogShellFull` |

## Autocmds

Registered per-buffer in [`lua/cmdlog/core/notes.lua`](../lua/cmdlog/core/notes.lua)
when a note buffer is opened and `notes.autosave` is enabled.

| Event(s)                                  | Scope             | Description                                  |
| ------------------------------------------ | ----------------- | --------------------------------------------- |
| `BufWritePost`, `TextChanged`, `TextChangedI` | Note buffer (buffer-local) | Writes the note buffer's content to disk |
