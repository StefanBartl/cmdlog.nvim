# Cmdlog Commands

## `:CmdlogNvimFull`

Shows the full list of commands from Neovim's `:`-history, including repeated entries. Useful for reviewing recent activity.

## `:CmdlogNvim`

Same as `:CmdlogNvimFull`, but filters out duplicates. Only the most recent occurrence of each command is kept.

## `:CmdlogFavorites`

Shows only your favorite commands. Use `<Tab>` inside any picker to toggle favorite status.

## `:CmdlogFull`

Combines your favorites and the full `:` history into a single list.
- Favorites appear at the top.
- Duplicate entries are shown.

## `:Cmdlog`

Same as `:CmdlogFull`, but filters the history to show each command only once.

## `:CmdlogShellFull`

Shows the full shell history, including duplicates.

## `:CmdlogShell`

Same as `:CmdlogShellFull`, but filters out duplicates.

---

### Notes

- Favorites are stored in: `<stdpath("data")>/cmdlog/favorites.json`
- All views support preview (Telescope) and insertion
- See [BINDINGS.md](./BINDINGS.md) for every keymap and [OPTIONS.md](./OPTIONS.md) for configuration
