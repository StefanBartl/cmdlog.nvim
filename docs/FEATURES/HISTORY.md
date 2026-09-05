# History sources

The different places cmdlog pulls command history from, and the pickers
built on top of each.

## Neovim command-line history

Reads Neovim's own `:` command-line history (the same list `:history cmd`
shows) via a Telescope or fzf-lua picker.

- **Module:** `cmdlog/core/history.lua`
- **Deleting:** `<C-x>` deletes the entry under the cursor, or —
  with entries marked via `mappings.toggle_selection` (default `<C-Space>`) —
  every marked one, asking once for the batch instead of once per command.
  The mappings call `delete_fn(cmd, on_done, opts)`; the two history sources
  do not natively have that shape (`history.delete_entry` is synchronous and
  returns a boolean, `shell.delete_entry` takes `(cmd, opts, on_done)`), so
  each picker wraps its source in an adapter. Passing them through raw was a
  real bug: the first never invoked the callback, leaving the picker open on
  a stale list, and the second raised
  `attempt to call local 'on_done' (a nil value)`.
- **Usercmds:** `:Cmdlog nvim` (deduplicated), `:Cmdlog nvim-full` (with duplicates) — see [COMPOSER.md](./COMPOSER.md)

## Shell history integration

Folds your shell's own history file into the pickers alongside Neovim
history, with per-shell path detection:

- `zsh` — `~/.zsh_history`
- `bash` — `~/.bash_history`
- `fish` — `~/.local/share/fish/fish_history`
- `nu` — `~/.config/nushell/history.txt`
- `ksh` — `~/.ksh_history`
- `csh` — `~/.history`
- `pwsh` — `%APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt`

`opts.shell_history_path` overrides auto-detection with a custom path.

- **Module:** `cmdlog/core/shell.lua`
- **Config:** `opts.shell_history_path` (default `"default"`, i.e. auto-detect),
  `opts.shell_history = { parse, matches }` (default `{}`, i.e. the built-in
  per-shell parsers)
- **Escape hatch:** the per-shell parsers are hardcoded, so a
  custom `HISTTIMEFORMAT`, a wrapper that rewrites the file, or an
  uncovered shell had no way in. `shell_history.parse(lines, shell)` replaces
  them. Its partner `shell_history.matches(line, cmd)` is what deletion
  needs — it has to locate the *raw line* a command came from — and setting
  `parse` without it makes deletion refuse rather than let the built-in
  matcher guess at a format it does not know and rewrite the wrong lines. A
  raising `parse` is contained: empty history plus a warning.
- **Usercmds:** `:Cmdlog shell` (deduplicated), `:Cmdlog shell-full` (with duplicates)

## Lua-mode history

A filtered view of Neovim history showing only Lua-mode entries —
`:lua ...`, `:lua= ...`, `:= ...`.

- **Module:** `cmdlog/ui/lua_picker.lua`
- **Usercmds:** `:Cmdlog lua`

## Project-based history

Records every `:` command run while inside a Git project (found by
walking up from cwd for a `.git` directory) into a separate,
project-keyed store, so `:Cmdlog project` shows only what actually
happened in *this* repo. Recording starts once the plugin is set up —
pre-existing Neovim history is not retroactively attributed to a
project, and running outside a Git repo (or before anything's been
recorded) just notifies and shows nothing.

- **Module:** `cmdlog/core/project_history.lua`
- **Config:** `opts.project_history_path`, gated by `opts.track_commands` (default `true`)
- **Usercmds:** `:Cmdlog project`

## Usage stats

Every tracked `:` command increments a per-command counter and
last-used timestamp; `:Cmdlog stats` lists commands sorted by usage
frequency, each annotated `[used Nx, last <date>]`. Only reflects
commands run since `track_commands` was enabled — there's no
retroactive count from pre-existing history.

- **Module:** `cmdlog/core/stats.lua`, `cmdlog/ui/stats_picker.lua`
- **Config:** `opts.stats_path`, gated by `opts.track_commands`
- **Usercmds:** `:Cmdlog stats`

## `extra_files`: folding in your own history files

Plain-text files (one command per line) folded into the pickers as
additional read-only sources — no favorites/tags/delete support for
these entries, just listed alongside Neovim/shell history.
`extra_files.history` entries are folded into the Neovim-history-based
pickers (`nvim`, `nvim-full`) and the combined pickers (bare `:Cmdlog`,
`:Cmdlog full`); `extra_files.all` entries only into the latter.

- **Module:** `cmdlog/core/extra_files.lua`
- **Config:** `opts.extra_files = { history = {}, all = {} }`

## Origin labels

The combined pickers (bare `:Cmdlog`, `:Cmdlog full`) label each
non-favorite entry `nvim`, `shell`, or `extra` (from `extra_files`) so
you can tell at a glance where a result actually came from. Favorites
are already distinguished by the `★` marker and carry no origin label.

- **Module:** `cmdlog/ui/picker_utils.lua` (`opts.label` hook)

## Cycling between pickers

`<C-s>` inside any picker rotates to the next one in a fixed order
(nvim → shell → favorites → project → back to nvim), carrying over
whatever prompt text was already typed — no need to close, retype, and
reopen a different `:Cmdlog` subcommand just to check a different
source with the same search term. Telescope only, for the same reason
risky-command highlighting and origin labels are: fzf-lua entries
double as the value fed back to its own actions, leaving no separate
hook to attach this to.

- **Module:** `cmdlog/ui/cycle.lua`
- **Config:** `mappings.cycle_source` (default `<C-s>`, set `false` to disable)
