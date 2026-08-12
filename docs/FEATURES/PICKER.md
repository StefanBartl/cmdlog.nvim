# Picker UI

The picker layer itself: backend choice, previews, the notes side
window, and the keymaps/entry-points around all of it.

## Picker backend: Telescope or fzf-lua

Every subcommand's picker is implemented against both backends;
`opts.picker` picks which one renders. Telescope has the fuller feature
set (previews, known-error highlighting, risky-command highlighting,
`<C-s>` cycling — all Telescope-only, see their own entries); fzf-lua is
the faster, more minimal option, with cross-platform preview support
except on Windows.

- **Module:** `cmdlog/ui/picker_utils.lua`
- **Config:** `opts.picker = "telescope"` (default) or `"fzf"`

## Command previews (Telescope only)

Previews the effect of the highlighted entry before you commit to
reusing it:

- `:edit <file>` — shows the file's contents if readable
- `:!<shell>` — simulates the shell command's output for supported commands
- `:term[inal] [cmd]` — runs `cmd` and shows its output, or notes there's no static preview for a bare `:term`
- `:help <topic>` — renders the help page via a headless Neovim instance
- `:lua <expr>` — evaluates the expression in-process and shows the result

- **Module:** `cmdlog/ui/telescope-previewer.lua`

## Notes side window

An editable, per-command notes buffer that opens in a vertical split
alongside the picker (Telescope) and stays in sync with the current
selection — jot down why a gnarly one-liner works, or what it broke
last time, right next to the command itself. Notes are plain files on
disk, one per normalized command, autosaved on `BufWritePost`/
`TextChanged`/`TextChangedI` by default.

- **Module:** `cmdlog/core/notes.lua`, `cmdlog/ui/telescope/notes_picker.lua`
- **Config:** `opts.notes = { enabled = true, dir = ..., format = "markdown", width = 60, autosave = true, persist = true }`

## Origin section dividers (Telescope only)

The combined pickers (`:Cmdlog`, `:Cmdlog full`) mix favorites, Neovim
history, shell history, and any `extra_files` entries into one list; each
non-favorite entry already carries a `[nvim]`/`[shell]`/`[extra]` suffix
(see `HISTORY.md`'s origin labels), but reading every line's suffix is
slower than seeing the blocks at a glance. A non-selectable `── nvim
history ──`-style divider row is spliced in before each origin block's
first entry — skipped entirely when fewer than two blocks are actually
non-empty, since a single-origin list has nothing to divide.

Only meaningful while the prompt is empty: dividers have an empty
`ordinal`, so the fuzzy sorter drops them out of view as soon as you start
typing — filtering has already broken the contiguous blocks by then
anyway. `<CR>`/`<Tab>`/`<C-t>`/`<C-x>`/etc. are all no-ops on a divider row
(it carries `value = false`, which every mapping in `ui/mappings.lua`
already guards on).

- **Module:** `cmdlog/ui/picker_utils.lua` (`M.section_dividers`, the
  `opts.sections` handling in `M.open_picker`)
- **Highlight:** `CmdlogSectionDivider` (linked to `Comment` by default)

## Known-error highlighting (Telescope only)

A command whose last run set a Vim error message is flagged with a `✗`
marker and highlight in the picker — a quiet warning before you reuse
something that already bit you once.

- **Module:** `cmdlog/core/errors.lua` (detection deferred via `vim.schedule()`, since `vim.v.errmsg` only updates after the command-line command actually executes)
- **Config:** `opts.errors_path`, gated by `opts.track_commands`

## Deleting history entries

`<C-x>` removes the selected command from its underlying history
source: Neovim's own `:` history via `histdel()` (in-memory/shada only,
no prompt), or the shell history file, which rewrites the file on disk
after a confirmation prompt since that touches state outside Neovim. In
the combined pickers, both sources are tried — whichever actually
contains the command gets updated.

- **Module:** `cmdlog/ui/mappings.lua`
- **Config:** `mappings.delete` (default `<C-x>`, set `false` to disable)

## Configurable picker keymaps

`<CR>` (insert without executing), `<Tab>` (toggle favorite), `<C-r>`
(refresh), `<C-x>` (delete), `<C-t>` (tag), `<C-e>` (add/edit a favorite's
note), `<C-g>` (peek a favorite's note), `<C-s>` (cycle source), `<C-z>`
(undo favorite), `<C-Up>`/`<C-Down>` (reorder favorite) are all
remappable or individually disableable via `setup({ mappings = {...} })`;
`mappings.enabled = false` turns all of them off at once. A legend of
the currently active ones is generated from `config.options.mappings`
(not hardcoded) and shown in the Telescope prompt title.

- **Module:** `cmdlog/ui/mappings.lua`, `cmdlog/bindings/picker_mappings.lua`
- **Config:** `opts.mappings` — see [../OPTIONS.md](../OPTIONS.md)
- **Keymaps:** see [../BINDINGS.md#picker-keymaps](../BINDINGS.md#picker-keymaps)

## Optional entry-point keymaps (which-key aware)

`opts.keymaps` maps a `:Cmdlog` subcommand name (`""` for bare
`:Cmdlog`) to a normal-mode `lhs`, registered with a `desc` so
which-key.nvim (v3+) picks it up with no extra registration step.
Derived from the same catalog the command tree itself is built from
(`bindings/usrcmds.lua`), so a newly added subcommand is mappable
immediately — no second list to keep in sync. Naming a subcommand that
doesn't exist logs a warning instead of silently producing a dead
keymap.

- **Module:** `cmdlog/bindings/keymaps.lua`, `cmdlog/integrations/which_key.lua`
- **Config:** `opts.keymaps = { [""] = "<leader>ch", favorites = "<leader>cf", ... }` (empty by default)

## `:checkhealth cmdlog`

Verifies the Neovim version, that `lib.nvim` is installed (the command
tree and cross-platform fs/notify helpers are built on it), that the
configured picker backend is actually installed, shell-history
detection, and notes-directory state.

- **Module:** `cmdlog/health.lua`
- **Usercmds:** `:checkhealth cmdlog`
