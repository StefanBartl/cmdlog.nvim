# Cmdlog Commands

One command, `:Cmdlog [subcommand]`, built via
[`lib.nvim.usercmd.composer`](https://github.com/StefanBartl/lib.nvim) with
`<Tab>` completion on the subcommand.

## `:Cmdlog`

Bare invocation (no subcommand). Combines favorites and Neovim `:`-history
into a single list, showing each command only once (duplicates filtered,
most recent occurrence kept).

## `:Cmdlog favorites`

Shows only your favorite commands. Use `<C-f>` inside any picker to toggle
favorite status.

## `:Cmdlog full`

Same as bare `:Cmdlog`, but keeps duplicate entries.

## `:Cmdlog nvim`

Shows only Neovim `:`-history, deduplicated (most recent occurrence kept).

## `:Cmdlog nvim-full`

Shows the full Neovim `:`-history, including duplicates.

## `:Cmdlog shell`

Shows shell command history, deduplicated (most recent occurrence kept).

## `:Cmdlog shell-full`

Shows the full shell command history, including duplicates.

---

### Notes

- Favorites are stored in: `~/.local/share/nvim-cmdlog/favorites.json`
- All views support preview and insertion
