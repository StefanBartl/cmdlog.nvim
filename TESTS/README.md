# Tests

Lightweight, framework-free tests for cmdlog.nvim. No network, no plugins
beyond `lib.nvim` and `ui.nvim` (both auto-detected as sibling repos, or via
`$REPOS_DIR`/`$LIB_NVIM_PATH`/`$UI_NVIM_PATH`). telescope.nvim (+ its own
plenary.nvim dependency) is optional and picked up the same way if present.

## Run

```sh
nvim -l TESTS/smoke_spec.lua
```

The script bootstraps its own `runtimepath` from its file location, so it
works from any working directory. It exits non-zero on the first failing
suite, making it CI-friendly.

## Coverage

Everything lives in `smoke_spec.lua`, one commented suite per area. It opens
with the original load-time gate — `require()` every module (skipping the
telescope-only previewer when telescope.nvim isn't on the runtimepath),
`setup({})`, and the bindings catalog — then works through real
assertion-based suites: `config.setup`'s option merging and mappings
fallback; `core.store`'s JSON persistence; `core.favorites` (load/save,
toggle, single-level undo, reordering, export/import merge-dedup, and
project-scoped storage against a real temp `.git` root); `core.shell` in
depth — `$SHELL`-based detection, the `shell_history_path` override, every
built-in per-shell history parser (zsh/bash/fish/nu/PSReadLine), per-shell
delete-line matching, and the confirm-dialog path via a stubbed
`ui.kit.confirm`; `core.errors`/`core.stats`/`core.tags` (each against a temp
JSON path); `core.project_history` (a real temp Git root, and the outside-any-
repo case); `core.extra_files`; `core.history` against Neovim's real `:`
command-line history (`histadd`/`histdel`); `core.utils.process_list`;
`core.risky` (which patterns matched, not just yes/no); `ui.preview_policy`
(what may be previewed, and why not); `ui.picker_utils.section_dividers`;
`ui.fzf-previewer`'s pure `command_previewer()` (no fzf-lua needed — it
returns a shell string); `ui.all_picker`/`ui.all_unique_picker`'s
cross-source merge, origin labelling and best-effort delete adapter (via a
monkey-patched `picker_utils.open_picker` and a stubbed `ui.mappings`, so
none of this needs a real picker backend); the empty-state guard clauses in
`ui.favorites_picker`/`ui.stats_picker`/`ui.lua_picker`/`ui.project_picker`;
`bindings.usrcmds`' catalog shape and real `:Cmdlog` registration/completion;
`bindings.keymaps`' catalog and optional entry-point keymaps;
`bindings.picker_mappings`; `bindings.catalog()`'s aggregation (including a
documented quirk, pinned so a future fix is deliberate); and
`integrations.which_key`'s no-op-without-which-key path plus its spec
building once `which-key` is stubbed in. It ends with `:checkhealth cmdlog`.

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

Deliberately left untested, and why:

- **`ui.cycle` and `ui.mappings`** — Telescope-only glue (`prompt_bufnr`,
  `map`, `telescope.actions`/`actions.state`) with no logic of their own once
  separated from a real picker session. The contracts they depend on
  (`delete_fn`'s signature, `favorites`/`tags` behaviour) are already pinned
  directly against `core.history`/`core.shell`/`core.favorites`/`core.tags`.
- **`ui.telescope-previewer`** — hard-requires `telescope.nvim`, which isn't
  on the runtimepath in this environment (and is skipped the same way by the
  module-load loop at the top of the file). Its decision logic is fully
  delegated to `ui.preview_policy`, which has its own suite.
- **`ui.history_picker`, `ui.history_unique_picker`, `ui.shell_picker`,
  `ui.shell_unique_picker`** — picker assembly plus a one-line
  signature-adapter around `core.history.delete_entry`/`core.shell.delete_entry`,
  both already covered directly. No guard clause, no merge/dedup logic of
  their own beyond what `core.utils.process_list` already owns.
- **`@types/init.lua`** — pure `---@class`/`---@alias` annotations, no
  runtime code.
- **`bindings/autocmds.lua`** — a static descriptive table with zero
  branches; nothing to assert beyond "the table exists," which the
  `bindings.catalog()` suite already does in passing.

## A note on isolation

Every suite that touches `config.options`, `vim.env.SHELL`, or the current
working directory restores it before moving on, and filesystem-backed
suites (`favorites`, `errors`, `stats`, `tags`, `project_history`) point
`config.options.*_path` at a fresh `vim.fn.tempname()` rather than the
user's real `stdpath("data")/cmdlog/` files. `core.history`'s suite is safe
to run against a real editor too: `nvim -l` runs with `shadafile=NONE` and
never sources user config, so `histadd`/`histdel` only ever touch this
process's in-memory `:` history, not any persisted shada file.
