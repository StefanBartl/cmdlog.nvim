# Favorites

Everything about marking commands as favorites, organizing them, and
moving them between machines.

## Favorites management

Mark any command in any picker as a favorite with `<Tab>`; favorites are
persisted to JSON and shown first/together in the favorites picker and
the combined pickers (marked with a `★`).

- **Module:** `cmdlog/core/favorites.lua` (`M.toggle`, `M.load`, `M.save`)
- **Config:** `opts.favorites_path` (default `~/.local/share/cmdlog/favorites.json`)
- **Usercmds:** `:Cmdlog favorites`
- **Keymaps:** `mappings.toggle_favorite` (default `<Tab>`) — see [../BINDINGS.md#keymaps](../BINDINGS.md#picker-keymaps)

## Favorite tags

Free-form labels attached to a favorite (`<C-t>` in the favorites
picker), stored separately from `favorites.json` so the flat favorites
list format never has to migrate. A command can carry any number of
tags; `M.filter(tag)` returns every favorite carrying a given one.

- **Module:** `cmdlog/core/tags.lua`
- **Config:** `opts.favorite_tags_path`
- **Keymaps:** `mappings.tag` (default `<C-t>`), favorites picker only — tags attach to favorites, so the mapping has nothing to do outside that picker

## Undo and manual reordering

`<C-z>` reverts the most recent `<Tab>` toggle — single-level, only the
last toggle is remembered, and only for the project/global favorites
file it applied to (switching projects invalidates a pending undo).
`<C-Up>`/`<C-Down>` in the favorites picker swap the selected favorite's
position in the persisted list order; display order there *is* that
persisted order, unlike other pickers where it's Telescope's own sort.

- **Module:** `cmdlog/core/favorites.lua` (`M.undo_last_toggle`, `M.move`)
- **Keymaps:** `mappings.undo_favorite` (default `<C-z>`), `mappings.move_favorite_up`/`move_favorite_down` (default `<C-Up>`/`<C-Down>`)

## Project-scoped favorites (opt-in)

By default all favorites live in one global file. With
`project_scoped.enabled = true`, cmdlog looks for a `.git` directory
upward from cwd and, if found, stores favorites in a dedicated
per-project file (`<favorites dir>/projects/<repo-name>-<hash>.json`)
instead. Off by default — existing favorites are untouched until you
opt in, and outside a Git repo the global file is still used even with
the option enabled.

- **Module:** `cmdlog/core/favorites.lua` (`get_favorites_path`)
- **Config:** `opts.project_scoped = { enabled = false }`

## Export / import

`:Cmdlog export [path]` writes the current favorites list to a JSON
file — `path` defaults to the favorites file's own path with a
`.export.json` suffix. `:Cmdlog import path` reads one back and merges
it with the current list: existing favorites are kept in place, new
ones appended, duplicates dropped. The two are format-compatible with
each other (import accepts anything export produced, or any hand-written
JSON array of command strings) — useful as a manual backup before a
risky edit, or to carry favorites from a laptop to a workstation.

- **Module:** `cmdlog/core/favorites.lua` (`M.export`, `M.import`)
- **Usercmds:** `:Cmdlog export [path]`, `:Cmdlog import path`

Note: `export`/`import` take a path argument, unlike every other
subcommand's zero-arg picker, so they have no normal-mode entry-point
keymap via `opts.keymaps` — those are wired for zero-arg subcommands
only.
