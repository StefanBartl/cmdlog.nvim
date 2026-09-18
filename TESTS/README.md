# Tests

Lightweight, framework-free tests for cmdlog.nvim. No network, no plugins
beyond `lib.nvim` and `ui.nvim` (both auto-detected as sibling repos, or via
`$REPOS_DIR`/`$LIB_NVIM_PATH`/`$UI_NVIM_PATH`). telescope.nvim (+ its own
plenary.nvim dependency) is optional and picked up the same way if present —
CI now checks it out as a real sibling specifically so the telescope-only
suites below run for real there instead of being skipped; locally, point
`$REPOS_DIR` (or the individual path vars) at a directory that has it, or
prepend it to the runtimepath yourself before requiring anything, e.g.:

```sh
nvim --cmd "lua vim.opt.rtp:append('/path/to/telescope.nvim'); vim.opt.rtp:append('/path/to/plenary.nvim')" -l TESTS/smoke_spec.lua
```

## Run

```sh
nvim -l TESTS/smoke_spec.lua
```

The script bootstraps its own `runtimepath` from its file location, so it
works from any working directory. It exits non-zero on the first failing
suite, making it CI-friendly.

## Coverage

Everything lives in `smoke_spec.lua`, one commented suite per area. It opens
with the original load-time gate — `require()` every module, `setup({})`,
and the bindings catalog — then works through real assertion-based suites:
`config.setup`'s option merging and mappings fallback; `core.store`'s JSON
persistence; `core.favorites` (load/save, toggle, single-level undo,
reordering, export/import merge-dedup, and project-scoped storage against a
real temp `.git` root); `core.tracker` (the `CmdlineLeave` autocmd itself,
driven with real keystrokes via `nvim_feedkeys(..., "x", ...)` rather than
`vim.cmd("normal! ...")` — the latter raises straight through `pcall` on an
invalid Ex command instead of setting `v:errmsg`, which this module's own
error-recording path depends on; covers `setup()`'s dedup-on-repeat-call,
`redact_patterns` suppression including a malformed pattern, and the deferred
project_history/stats/errors fan-out); `core.shell` in depth — `$SHELL`-based
detection, the SHELL-unset candidate-probing branch (HOME faked via
`vim.uv.os_homedir`, `%APPDATA%` via the env var, so the result never depends
on what the dev machine actually has lying around), the `shell_history_path`
override, every built-in per-shell history parser (zsh/bash/fish/nu/PSReadLine),
per-shell delete-line matching, and the confirm-dialog path via a stubbed
`ui.kit.confirm`; `core.errors`/`core.stats`/`core.tags` (each against a temp
JSON path); `core.project_history` (a real temp Git root, and the outside-any-
repo case); `core.extra_files`; `core.history` against Neovim's real `:`
command-line history (`histadd`/`histdel`); `core.utils.process_list`;
`core.risky` (which patterns matched, not just yes/no) and `ui.risky_test`'s
`:Cmdlog risky test` report (real assertions on the notified message, not
just "it didn't throw"); `ui.preview_policy` (what may be previewed, and why
not); `ui.picker_utils.section_dividers` plus, when telescope.nvim is on the
runtimepath, `open_picker`'s actual Telescope branch — entry decoration
priority (favorite/known-bad/risky), the mappings-legend prompt title, and
section-divider splicing, via stubbed `telescope.pickers.new`/
`finders.new_table` rather than the usual monkey-patched `open_picker` itself
— and, when fzf-lua is on the runtimepath, `open_picker`'s fzf branch (the
argv/options `fzf_exec` actually receives, and the default action's
dispatch); `ui.telescope-previewer`'s `define_preview` branch dispatch (refused/file/
lua/help/terminal/shell, `lib.nvim.system.job.start` stubbed so nothing ever
actually spawns); `ui.mappings`' `attach_mappings` factory (select, toggle
favorite, refresh, undo, tag, reorder, multi-select toggle, and delete's
single-vs-multi-selection/confirm-once/failure-aggregation logic, with
`telescope.actions`/`actions.state` stubbed the way sessions.nvim's
`picker_spec.lua` already does); `ui.cycle`'s rotation (name lookup + modulo
wraparound through all four pickers, gated correctly on
`mappings.enabled`/`cycle_source`); `ui.fzf-previewer`'s pure
`command_previewer()` (no fzf-lua needed — it returns a shell string);
`ui.all_picker`/`ui.all_unique_picker`'s cross-source merge, origin labelling
and best-effort delete adapter (via a monkey-patched `picker_utils.open_picker`
and a stubbed `ui.mappings`, so none of this needs a real picker backend); the
empty-state guard clauses in
`ui.favorites_picker`/`ui.stats_picker`/`ui.lua_picker`/`ui.project_picker`;
`bindings.usrcmds`' catalog shape and real `:Cmdlog` registration/completion;
`bindings.keymaps`' catalog and optional entry-point keymaps;
`bindings.picker_mappings`; `bindings.catalog()`'s aggregation (including a
documented quirk, pinned so a future fix is deliberate); and
`integrations.which_key`'s no-op-without-which-key path plus its spec
building once `which-key` is stubbed in. It ends with `:checkhealth cmdlog`,
driven against a recording `vim.health` (mirroring diff.nvim's
`health_spec.lua`) so each branch's actual verdict is asserted, not just "it
ran".

A few of these exist because the failure they pin is easy to reintroduce
silently:

- **`:history`'s `>` marker.** Neovim's `:history` output marks the
  most-recently-added entry with a leading `>` instead of an index.
  `core.history.get_command_history()`'s pattern now accepts that marker
  alongside a plain index, and `core.history`'s own suite pins this by
  asserting the entry left sitting in that slot is still returned.
- **`shell_history.parse` without `shell_history.matches`.** `delete_entry`
  refuses to guess at a custom format's raw-line syntax rather than risk
  deleting the wrong line.
- **The `delete_fn` contract.** `history.delete_entry` is `(cmd) -> boolean`;
  `shell.delete_entry` is `(cmd, opts, on_done)`. Passed straight through to
  a picker mapping expecting `(cmd, on_done, opts)`, the first never called
  its callback and the second raised on a nil call. Both go through adapters
  now, and this pins the underlying signatures those adapters assume.
- **`:help x | !cmd` as command injection** through the previewers, which
  interpolate a history entry's argument into a `-c` string (and, on the fzf
  side, into a shell string too). `ui.preview_policy` is the single place
  that decides what may be previewed; the previewer suite exercises the
  refusal paths (disabled, risky, unsafe-argument, interactive) directly
  rather than trusting that each previewer reimplements the check correctly.
- **`health.check()`'s unconditional `require` into lib.nvim.** The last line
  used to be `require("lib.nvim.bindings.usercmd.composer").checkhealth(...)`
  with no guard, so a genuinely missing lib.nvim made `:checkhealth cmdlog`
  abort right after the very line that diagnosed the problem — the user never
  got to read it. Same family as diff.nvim/emojis.nvim/gopath.nvim's health
  checks. Fixed (now `pcall`-guarded like the check above it) and pinned by
  temporarily replacing the composer module with one that throws.
- **`project_history.get_git_root()`'s raw return value.** Verified
  empirically (not just asserted): `vim.fs.find`/`vim.fs.dirname` already
  return forward slashes on Windows, so the module's own defensive
  `dir:gsub("\\", "/")` never has anything to do. Pinned directly on the raw
  value rather than on a normalized copy, so a regression in either `vim.fs.*`
  or the module's own gsub would actually be caught.

Deliberately left untested, and why:

- **`ui.history_picker`, `ui.history_unique_picker`, `ui.shell_picker`,
  `ui.shell_unique_picker`** — picker assembly plus a one-line
  signature-adapter around `core.history.delete_entry`/`core.shell.delete_entry`,
  both already covered directly (and, since round 2, so is the
  `attach_mappings`/`cycle.attach` wiring they build on top of `ui.mappings`/
  `ui.cycle`). No guard clause, no merge/dedup logic of their own beyond what
  `core.utils.process_list` already owns.
- **`core.tracker`'s abort guard** (`args.data.abort` on `CmdlineLeave`) —
  investigated, not pinned. Simulating a genuine cmdline abort headlessly via
  `nvim_feedkeys` proved unreliable while writing this suite: `<C-c>` left
  `args.data.abort` unset and the command still didn't run, while `<Esc>`
  actually let the command *execute* — neither reproduces real interactive
  abort behaviour under `nvim -l`, so asserting either would pin an artifact
  of headless key injection rather than the guard clause itself.
- **`core.shell`'s full candidate-probing fallback order** beyond the first
  match — the suite pins that the highest-priority candidate wins over a
  simultaneously-present lower one (Windows: PowerShell over bash; Unix: zsh
  over bash) and that "nothing found" returns `""`, but does not walk every
  remaining candidate in between; the loop itself has no per-candidate branch
  worth pinning individually.
- **`@types/init.lua`** — pure `---@class`/`---@alias` annotations, no
  runtime code.
- **`bindings/autocmds.lua`** — a static descriptive table with zero
  branches; nothing to assert beyond "the table exists," which the
  `bindings.catalog()` suite already does in passing.
- **The interactive window either backend actually opens** — telescope's own
  `Previewer:preview()`/`:find()` loop, fzf-lua's real floating terminal
  (cmdlog never references snacks.nvim as a backend, so that one was never a
  candidate). Re-verified this round that telescope.nvim and fzf-lua are both
  real siblings here (via lazy.nvim's data dir locally, and telescope.nvim via
  a fresh checkout in CI) — that changed the previous verdict for what's
  *around* that window: `ui.telescope-previewer`/`ui.mappings`/`ui.cycle` and
  both of `open_picker`'s backend branches now have real suites (stubbing
  just `pickers.new`/`finders.new_table`/`fzf_exec` themselves, capturing what
  cmdlog hands them), not skips. Only the window loop each library owns
  internally stays out of scope, regardless of availability.

## A note on isolation

Every suite that touches `config.options`, `vim.env.SHELL`, or the current
working directory restores it before moving on, and filesystem-backed
suites (`favorites`, `errors`, `stats`, `tags`, `project_history`) point
`config.options.*_path` at a fresh `vim.fn.tempname()` rather than the
user's real `stdpath("data")/cmdlog/` files. `core.history`'s suite is safe
to run against a real editor too: `nvim -l` runs with `shadafile=NONE` and
never sources user config, so `histadd`/`histdel` only ever touch this
process's in-memory `:` history, not any persisted shada file.

The `core.shell` SHELL-unset probing suite goes one step further and fakes
`vim.uv.os_homedir()` itself (restored after) rather than relying on
`$HOME`/`$USERPROFILE`, because `lib.nvim.cross.fs.expand_path` resolves `~`
through that call directly and ignores the env vars — without this, the
suite's result would depend on whatever the real dev machine happens to have
under its actual home directory.

The telescope-dependent suites (`ui.telescope-previewer`, `ui.mappings`,
`ui.cycle`, and `picker_utils.open_picker`'s Telescope branch) each check
`pcall(require, "telescope...")` first and skip with a counted `skip` line if
it fails, the same way the module-load loop at the top of the file already
did for one module. They stub collaborator functions in place on the shared
module table (`telescope.pickers.new`, `finders.new_table`,
`telescope.previewers.new_buffer_previewer`, `telescope.actions*`,
`lib.nvim.system.job.start`) rather than reloading anything through
`package.loaded`, which works here because every call site in `lua/cmdlog`
does `require(...)` fresh at call time instead of caching the collaborator in
a file-local at module load.
