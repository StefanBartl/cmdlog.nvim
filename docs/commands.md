# Cmdlog Commands

One command, `:Cmdlog [subcommand]`, built via
[`lib.nvim.bindings.usercmd.composer`](https://github.com/StefanBartl/lib.nvim) with
`<Tab>` completion on the subcommand.

## `:Cmdlog`

Bare invocation (no subcommand). Combines favorites and Neovim `:`-history
into a single list, showing each command only once (duplicates filtered,
most recent occurrence kept).

## `:Cmdlog favorites`

Shows only your favorite commands. Use `<Tab>` inside any picker to toggle
favorite status, and `<C-t>` here to tag the selected favorite. Both keys
are configurable — see `mappings` in [configuration.md](./configuration.md).

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

## `:Cmdlog risky test <command>`

Not a picker. Reports which of the configured `risky_patterns` match the
given command line, so the list can be tuned without guessing from picker
colours:

```
:Cmdlog risky test git reset --hard HEAD~1
```

The whole rest of the line is the command under test — it is not a quoted
argument. Matching ignores `highlight_risky` (that gates display, not
evaluation) and the output says so when the switch is off.

## `:Cmdlog export [path]`

Exports the current favorites list to a JSON file, for backup or moving
favorites between machines. `path` defaults to the favorites file's own
path with a `.export.json` suffix.

## `:Cmdlog import path`

Imports favorites from a JSON file (as produced by `:Cmdlog export`, or
hand-written) and merges them with the current list — existing favorites
are kept, new ones appended, duplicates dropped.

---

### Notes

- Favorites are stored in `stdpath("data")/cmdlog/favorites.json`
  (`~/.local/share/cmdlog/favorites.json` on Linux)
- Commands prefixed with `✗` (Telescope only) are known to have errored
  the last time they ran (see `core/errors.lua`)
- **The in-picker keys below are Telescope's.** Under `picker = "fzf"`
  only `<CR>` is bound, and it *runs* the selected command instead of
  inserting it — no favorite toggle, no tag, no delete
- Use `<C-t>` inside the favorites picker to tag a command; tags are
  shown alongside favorites
- Use `<C-z>` to undo the last favorite toggle, and `<C-Up>`/`<C-Down>`
  inside the favorites picker to reorder entries manually
- Use `<C-s>` inside any picker to rotate to the next one (nvim → shell →
  favorites → project → …), keeping the current prompt text
- In the combined pickers (`:Cmdlog`, `:Cmdlog full`), non-favorite
  entries are labelled `nvim`/`shell`/`extra` by origin
- `require("cmdlog").setup({ keymaps = { ... } })` registers normal-mode
  keymaps for any subcommand, picked up by which-key.nvim when installed
- `export`/`import` aren't in the `keymaps` catalog (they take a required
  path argument), so they have no normal-mode entry-point keymap
