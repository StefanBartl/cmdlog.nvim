# Bindings Cheatsheet

Single reference for every user command, in-picker keymap and autocmd that
`nvim-cmdlog` registers. The source of truth lives in
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

## Picker keymaps

Implemented in [`lua/cmdlog/ui/mappings.lua`](../lua/cmdlog/ui/mappings.lua)
(catalog mirrored in [`lua/cmdlog/bindings/picker_mappings.lua`](../lua/cmdlog/bindings/picker_mappings.lua))
and applied inside every picker (Telescope insert mode). All are
user-configurable via `setup({ mappings = { ... } })` — see
[OPTIONS.md](./OPTIONS.md). Set a value to `false` to disable it, or
`mappings.enabled = false` to disable all of them at once.

| Default | Config key        | Action                                            |
| ------- | ------------------ | -------------------------------------------------- |
| `<CR>`    | `mappings.select`          | Insert the selected command into the cmdline (no execution) |
| `<Tab>`   | `mappings.toggle_favorite` | Toggle favorite status for the selected command   |
| `<C-r>`   | `mappings.refresh`         | Refresh the current picker                        |
| `<C-x>`   | `mappings.delete`          | Delete the selected entry from its underlying history (Neovim `:` history or the shell history file) |

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
