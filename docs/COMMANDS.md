# Cmdlog Commands

## `:Cmdlog`

Shows the full list of commands from Neovim's `:`-history, including repeated entries. Useful for reviewing recent activity.

## `:CmdlogUnique`

Same as `:Cmdlog`, but filters out duplicates. Only the most recent occurrence of each command is kept.

## `:CmdlogFavorites`

Shows only your favorite commands. Use `<C-f>` inside any picker to toggle favorite status.

## `:CmdlogAll`

Combines your favorites and the full `:` history into a single list.
- Favorites appear at the top.
- Duplicate entries are shown.

## `:CmdlogAllUnique`

Same as `:CmdlogAll`, but filters the history to show each command only once.

---

### Notes

- Favorites are stored in: `~/.local/share/nvim-cmdlog/favorites.json`
- All views support preview and insertion
