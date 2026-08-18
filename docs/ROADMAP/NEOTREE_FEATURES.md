# Features from cmdlog.nvim worth porting into filetree.nvim

Cross-check of `cmdlog.nvim` features against `e:\repos\filetree.nvim`.
These are candidates only — nothing here has been implemented in
filetree.nvim yet. Target: cross-platform, filetree-manager-agnostic
(Neotree, NvimTree, Netrw, ...).

## Favorites system (persistent, JSON-backed)

- **Origin**: `lua/cmdlog/core/favorites.lua:161` (`M.load`), `:194` (`M.save`),
  `:255` (`M.toggle`), `:279` (`M.is_favorite`)
- **Fits into**: a `filetree.favorites` core module, mirroring the existing
  `filetree/bindings` layout — pinned/favorite paths shown in a dedicated
  picker or pinned section of the tree.
- **Notes**: `favorites.lua` is defensive about Windows path/mkdir quirks
  (tries `vim.fn.mkdir`, then a manual libuv walk, then falls back to
  `plenary.Path`). That fallback chain is directly reusable for any
  filetree feature that persists JSON to `stdpath("data")`.

## Per-entry notes (buffer with autosave)

- **Origin**: removed from cmdlog.nvim -- the side-window glue could not be
  made to coexist with Telescope (leaving the prompt window closes the
  picker). Read it out of git history: `lua/cmdlog/core/notes.lua`,
  `lua/cmdlog/ui/telescope/notes_picker.lua` and `open_notes_window` in
  `lua/cmdlog/ui/picker_utils.lua`, all as of commit 1ecd416.
- **Fits into**: "notes per file/directory" — a side split showing/editing a
  markdown note tied to the selected tree entry, autosaved on
  `TextChanged`/`TextChangedI`/`BufWritePost`.
- **Notes**: A filetree port should open the note in a normal window it owns,
  not as a split created while a picker has focus. Key naming scheme in
  `notes.lua` (`note_key`) sanitizes an
  arbitrary string into a filesystem-safe filename — same technique applies
  to turning an absolute file path into a note filename.

## Unique/dedup history views

- **Origin**: `lua/cmdlog/ui/history_unique_picker.lua`,
  `all_unique_picker.lua` (keep latest occurrence, drop older duplicates)
- **Fits into**: a "recent files/dirs" picker in filetree.nvim that dedups
  by path and keeps only the most recent visit.

## Cross-platform path/env expansion

- **Origin**: `lua/cmdlog/core/shell.lua:58` (`expand_path_template`) — handles
  `~`, POSIX `$VAR`, and Windows `%VAR%` in one function, then normalizes
  slashes.
- **Fits into**: any filetree config option that accepts a path (e.g. a
  custom root, ignore file, or export location) should reuse this expansion
  logic instead of relying only on `vim.fn.expand`.

## Config: DEFAULTS + deep-merge + type file

- **Origin**: `lua/cmdlog/config/DEFAULTS.lua`, `lua/cmdlog/config/init.lua`,
  `lua/cmdlog/@types/init.lua`
- **Fits into**: filetree.nvim already has a similar structure
  (`docs/BINDINGS.lua` catalog pattern); worth aligning the config module
  layout (`config/DEFAULTS.lua` + `config/init.lua` + typed `@class`) between
  the two plugins for consistency across `StefanBartl/*.nvim`.

## `:checkhealth` module

- **Origin**: `lua/cmdlog/health.lua` — checks Neovim version, required
  dependency (plenary/telescope/fzf-lua depending on config), and a
  feature-specific runtime check (shell detection / notes dir).
- **Fits into**: filetree.nvim health check for its file-manager backends
  (Neotree/NvimTree/Netrw) — verify the configured backend is actually
  installed, similar to the `picker` check here.

## Opt-in, which-key-aware entry keymaps

- **Origin**: `lua/cmdlog/config/DEFAULTS.lua` (`keymaps` table, disabled by
  default), `lua/cmdlog/bindings/keymaps.lua`
- **Fits into**: general pattern for any `StefanBartl/*.nvim` plugin — never
  claim a leader key by default; let the user opt in and assign keys; always
  set `desc` so which-key.nvim v3 auto-discovers it without an explicit
  `wk.register()` call.
