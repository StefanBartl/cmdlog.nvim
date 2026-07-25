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

## `:Cmdlog project`

Shows command history recorded while working inside the current Git
project (`.git` root), deduplicated. Only commands run since tracking
was enabled (`track_commands`, on by default) are recorded — there is no
retroactive attribution of pre-existing Neovim history to a project.
Notifies and does nothing if you're not inside a Git repository, or if
nothing has been recorded yet for it.

## `:Cmdlog lua`

Shows only Lua-mode command history (`:lua ...`, `:lua= ...`, `:= ...`),
deduplicated.

## `:Cmdlog stats`

Shows commands sorted by usage frequency (most-used first), each
annotated with `[used Nx, last <date>]`. Only reflects commands run
since tracking was enabled.

---

### Notes

- Favorites are stored in: `~/.local/share/nvim-cmdlog/favorites.json`
- All views support preview and insertion
- Commands prefixed with `✗` (Telescope only) are known to have errored
  the last time they ran (see `core/errors.lua`)
- Use `<C-t>` (Telescope) or `ctrl-t` (fzf-lua) inside the favorites
  picker to tag a command; tags are shown alongside favorites
- `require("cmdlog").setup({ keymaps = { ... } })` registers normal-mode
  keymaps for any subcommand, picked up by which-key.nvim when installed
