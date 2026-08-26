# Composer

## The `:Cmdlog <subcommand>` command tree

Every picker cmdlog offers is a route under one command, `:Cmdlog`, built on
`lib.nvim.bindings.usercmd.composer` instead of ten separate `:CmdlogXxx` commands.
`<Tab>` completes the subcommand name. This replaced an earlier surface of
seven flat commands (`:CmdlogFavorites`, `:CmdlogNvimFull`, ...) — a repo
still on an old `docs/BINDINGS.md` or blog post describing those flat names
is describing the pre-merge plugin, not this one.

- **Tab:** true
- **Module:** `cmdlog/bindings/usrcmds.lua` (`M.catalog`, `M.register`)
- **Usercmds:** see the table below

`M.catalog` is the single list every route, every picker keymap
(`keymaps.*` in `setup()`) and `docs/BINDINGS.md` itself derive from —
adding a subcommand means adding one entry here, nowhere else. Two routes,
`export` and `import`, are registered directly in `M.register()` instead of
living in `M.catalog`: both take a path argument, unlike every catalog
entry's zero-arg picker function, so they're kept out of the list that
`bindings.keymaps` also reads to build zero-arg entry-point keymaps.

### The current subcommand list

- *(bare)* `:Cmdlog` — favorites + history combined, deduplicated
- `:Cmdlog full` — all commands, including duplicates
- `:Cmdlog nvim` — Neovim `:`-command history, deduplicated
- `:Cmdlog nvim-full` — Neovim `:`-command history, including duplicates
- `:Cmdlog shell` — shell command history, deduplicated
- `:Cmdlog shell-full` — shell command history, including duplicates
- `:Cmdlog favorites` — favorited commands
- `:Cmdlog project` — command history for the current Git project
- `:Cmdlog lua` — Lua-mode command history (`:lua`, `:lua=`, `:=`), deduplicated
- `:Cmdlog stats` — commands sorted by usage frequency
- `:Cmdlog export [path]` — *(action, not a picker)* writes favorites to JSON
- `:Cmdlog import path` — *(action, not a picker)* merges favorites from JSON

### `full` vs. non-`full`

The plain form of a history subcommand (`nvim`, `shell`, bare `:Cmdlog`)
dedupes by command text, keeping the most recent occurrence — what you
almost always want when hunting for "that command I ran earlier". The
`-full` / `full` variant keeps every occurrence, in original order,
including runs of the exact same command minutes apart. Reach for the
`full` variant when the *repetition itself* is the thing you care about
(e.g. "how many times did I actually run this today", cross-checked
against `:Cmdlog stats`), not as the default way to browse history.

### Discovering the current routes without leaving the editor

The catalog is also readable at runtime, which is the more reliable
source than any static doc page (including this one) if the two ever
disagree:

```
:lua vim.print(require("cmdlog.bindings").catalog())
```
