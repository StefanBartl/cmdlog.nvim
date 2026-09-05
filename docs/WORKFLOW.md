# Workflow — getting real use out of cmdlog.nvim day to day

Every feature here is documented on its own elsewhere
(`docs/commands.md`, `docs/configuration.md`, `docs/FEATURES/`). This is the
different question: once you have ten `:Cmdlog` subcommands, favorites,
tags, project scoping and stats all sitting there, *how do they actually
combine* into something you reach for daily, rather than a picker you
open once after install and forget.

## Start from bare `:Cmdlog`, not from picking a subcommand first

The instinct when this plugin has ten subcommands is to think about
which one you want before you type anything. Don't — bare `:Cmdlog`
already gives you favorites + all history, deduplicated, and covers the
"I know roughly what I typed, let me find it" case that's most of your
actual usage. Reach for a specific subcommand only when you already
know you want a *narrower* slice: `:Cmdlog shell` when you're sure it
was a shell command, `:Cmdlog project` when you're sure it was run in
this repo, `:Cmdlog favorites` when you know you starred it.

## `full` / `-full` is for counting, not for browsing

`:Cmdlog nvim` and `:Cmdlog shell` dedupe by command text and keep the
most recent run — that's what you want when hunting for a specific
command. `:Cmdlog nvim-full` / `:Cmdlog shell-full` / `:Cmdlog full`
keep every occurrence in order, duplicates included. The only reason to
reach for the `-full` variant is when the *repetition* is the thing you
care about — "did I really run this five times today" — and even then
`:Cmdlog stats` (below) usually answers that faster, since it's already
counted for you.

## A real combo: shell command → favorite → tag

You run a gnarly one-liner in a terminal, it works, and you don't want
to reconstruct it from memory next time:

```
:Cmdlog shell
```

find it, `<Tab>` to favorite it, then jump straight to the favorites
picker and `<C-t>` to tag it (`docker`, `deploy`, whatever groups it
with commands like it):

```
:Cmdlog favorites
```

`<C-t>` on the now-favorited entry. Tags are stored separately from
`favorites.json` (`cmdlog/core/tags.lua`), so this never touches the
favorites list's own format — tagging is purely additive.

## Project-scoped work: know which favorites file you're actually looking at

`project_scoped.enabled = true` gives every Git repo its own
`favorites.json`, resolved by walking up from cwd for a `.git`
directory. This is worth turning on only once you've noticed your
global favorites list mixing unrelated repos' commands together — until
then it's one more thing to keep track of. The trap: with it enabled,
opening `:Cmdlog favorites` *outside* any Git repo (a scratch buffer, a
`$HOME`-rooted `nvim`) silently falls back to the global file, not an
empty one — if a favorite you expect isn't there, check whether you're
actually inside the project you think you are before assuming it's
gone.

`:Cmdlog project` is the read-only counterpart for plain history (not
favorites): it shows commands *recorded* while inside the current
project, and recording only starts once the plugin is set up —
pre-existing Neovim history is never retroactively attributed to a
project you open later.

## Cycling sources without losing your search

Mid-search in one picker and not sure if the command was shell or
Neovim history? Don't close and retype — `<C-s>` rotates to the next
picker (nvim → shell → favorites → project → back to nvim) carrying
over whatever you'd already typed into the prompt. This is Telescope
only: fzf-lua's entries double as the value fed back to its own
actions, so there's no separate hook to attach a same-prompt rotation
to.

## Stats before favoriting, not after

`:Cmdlog stats` sorts by actual usage frequency, annotated
`[used Nx, last <date>]`. Worth checking *before* you start manually
favoriting things — if something's already in your top ten by usage,
favoriting it just adds a `★` to something you were already finding
fine on its own. Favorite the things stats *doesn't* surface: the
one-off you'll need again in three weeks and won't remember well enough
to search for.

## Export before a risky edit, import after a machine switch

`:Cmdlog export` (no path) writes your current favorites to
`<favorites path>.export.json` — a cheap safety net to run before you
go tag-reorganizing a long list, since `<C-z>` only undoes the single
most recent toggle, not a whole editing session.
`:Cmdlog import <path>` merges a file back in additively (existing
favorites kept, new ones appended, duplicates dropped) — the same
command works for restoring your own backup or for carrying favorites
from a laptop to a workstation, since import doesn't care whether the
JSON came from `export` or was hand-written.

## The trap: `redact_patterns` protects cmdlog's own storage, not your shell

`opts.redact_patterns` (`password`, `secret`, `token`, `Bearer`,
`api[-_]?key` by default) stops a matching `:` command from being
written to project history, stats, or the error log — all three are
plaintext JSON under `stdpath("data")`. It does **not** touch Neovim's
own `:` history or your shell's history file; those are outside
cmdlog's control and get whatever your shell/Neovim itself decided to
keep. If a secret already leaked into one of those, `<C-x>` (delete)
in the relevant picker removes it from there specifically — redaction
only prevents the *next* one from landing in cmdlog's own stores.

## Telescope vs fzf-lua: pick based on what you actually use pickers for

| You mostly want... | Use |
|---|---|
| Previews (`:edit`, `:help`, `:lua`, shell-output simulation) | Telescope |
| Known-error / risky-command highlighting | Telescope |
| `<C-s>` cycling between sources mid-search | Telescope |
| Fastest possible open/close, minimal UI | fzf-lua |
| Previews on Linux/macOS without Telescope's weight | fzf-lua (POSIX only — no preview on Windows) |

Both back every subcommand identically otherwise — `opts.picker`
changes rendering, not which pickers exist.
