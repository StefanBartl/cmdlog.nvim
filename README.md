> **Alpha stage — active development.** This repository is in its development phase — breaking changes are to be expected at any time. Pin a commit or tag if you depend on it.

# cmdlog.nvim

```
 ██████╗███╗   ███╗██████╗ ██╗      ██████╗  ██████╗
██╔════╝████╗ ████║██╔══██╗██║     ██╔═══██╗██╔════╝
██║     ██╔████╔██║██║  ██║██║     ██║   ██║██║  ███╗
██║     ██║╚██╔╝██║██║  ██║██║     ██║   ██║██║   ██║
╚██████╗██║ ╚═╝ ██║██████╔╝███████╗╚██████╔╝╚██████╔╝
 ╚═════╝╚═╝     ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝
                                            .nvim
```

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Neovim](https://img.shields.io/badge/Neovim-0.9%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io)
[![Lua](https://img.shields.io/badge/Lua-5.1%2FLuaJIT-2C2D72?logo=lua&logoColor=white)](https://www.lua.org)
![Status](https://img.shields.io/badge/status-alpha-red)

> Pairs well with [pickers.nvim](https://github.com/StefanBartl/pickers.nvim):
> pickers.nvim is the general fuzzy-picker surface over files, buffers and
> symbols, cmdlog.nvim is the one over what you already typed — same
> "telescope or fzf-lua, your choice" style, different corpus.
> And with [filetree.nvim](https://github.com/StefanBartl/filetree.nvim):
> command reuse and file navigation are the two halves of not retyping things.

Interactively view, search, and reuse your Neovim command-line (`:`) history
and your shell history, through Telescope or fzf-lua.

Commands are inserted into the command-line, never executed for you — the
plugin is for recall, not for automation. On top of plain history it keeps
favorites, per-project history, usage stats, and flags commands that errored
or look destructive before you run them a second time.

Expect bugs, especially around shell history on Windows.

![Cmdlog Picker UI](./docs/assets/Cmdlog-Picker-UI.png)

---

## Table of contents

- [Quickstart](#quickstart)
- [Features](#features)
- [Commands](#commands)
- [Inside a picker](#inside-a-picker)
- [Documentation](#documentation)
- [Feedback](#feedback)
- [License](#license)

---

## Quickstart

Requires Neovim **0.9+**, [lib.nvim](https://github.com/StefanBartl/lib.nvim),
and one picker backend — [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
(default) or [fzf-lua](https://github.com/ibhagwan/fzf-lua).

```lua
{
  "StefanBartl/cmdlog.nvim",
  lazy = false,
  dependencies = {
    "StefanBartl/lib.nvim",          -- required
    "nvim-telescope/telescope.nvim", -- or "ibhagwan/fzf-lua"
  },
  opts = {}, -- picker defaults to "telescope"; set `picker = "fzf"` to switch
}
```

Then open the combined picker — favorites plus history, deduplicated:

```
:Cmdlog
```

`lazy = false` is deliberate: `setup()` starts the tracker that records your
`:` commands, so a `cmd`/`keys` trigger costs you everything typed before the
first `:Cmdlog`. Other package managers, the lazy-loading variants, and the
backend comparison are in [docs/installation.md](docs/installation.md).

Verify your setup any time with:

```
:checkhealth cmdlog
```

---

## Features

![Cmdlog Picker Demo](./docs/assets/Cmdlog-Picker-Demo.gif)

- **Neovim and shell history in one list** — `zsh`, `bash`, `fish`, `nu`,
  `ksh`, `csh` and PowerShell history files are detected per shell; entries in
  the combined pickers are labelled by origin and separated by divider rows.
- **Favorites and tags, persisted** — `<Tab>` marks, `<C-t>` tags, `<C-z>`
  undoes, `<C-Up>`/`<C-Down>` reorder; `:Cmdlog export`/`import` moves the
  list between machines.
- **Project-scoped history and favorites** — history recorded inside the
  current Git root, and optionally a separate favorites file per project.
- **Usage stats** — commands sorted by how often you actually ran them,
  annotated with the last use.
- **Risky-command highlighting** — `rm -rf`, `git reset --hard`, `:qa!` and
  friends stand out before you reuse them; the pattern list is yours to tune,
  and `:Cmdlog risky test <cmd>` says which pattern fired.
- **Known-error markers** — a command whose last run set an error message is
  flagged with `✗`.
- **Privacy filter** — commands matching `password`, `token`, `Bearer`, … are
  never written to cmdlog's own plaintext stores.
- **Previews** — `:edit` shows the file; `:help`, `:lua`, `:!` and `:term`
  show what *would* run, and only actually run it if you opt in with
  `preview_execute = true`.
- **Deleting entries** — `<C-x>` removes a command from its real source, be
  that Neovim's `:` history or the shell history file.
- **Your own history files** — `extra_files` folds arbitrary plain-text
  command lists in as read-only sources.
- **Configurable keys, which-key aware** — every in-picker key is remappable
  or disableable, and optional normal-mode entry points carry a `desc`.

One page per feature, with the reasoning behind each, in
[docs/FEATURES/README.md](docs/FEATURES/README.md).

![Favorites Picker](./docs/assets/Cmdlog-Favorites-Picker.png)

---

## Commands

One verb, `:Cmdlog [subcommand]`, with `<Tab>` completion.

| Command                    | Shows                                                     |
| -------------------------- | --------------------------------------------------------- |
| `:Cmdlog`                  | Favorites and history combined, deduplicated               |
| `:Cmdlog full`             | The same, with duplicates                                  |
| `:Cmdlog nvim`             | Neovim `:` history, deduplicated                           |
| `:Cmdlog nvim-full`        | Neovim `:` history, with duplicates                        |
| `:Cmdlog shell`            | Shell history, deduplicated                                |
| `:Cmdlog shell-full`       | Shell history, with duplicates                             |
| `:Cmdlog favorites`        | Commands you marked with `<Tab>`                           |
| `:Cmdlog project`          | History recorded inside the current Git project            |
| `:Cmdlog lua`              | Lua-mode history only (`:lua`, `:lua=`, `:=`)              |
| `:Cmdlog stats`            | Commands sorted by usage frequency                         |
| `:Cmdlog risky test <cmd>` | Which `risky_patterns` match a given command line          |
| `:Cmdlog export [path]`    | Writes favorites to JSON                                   |
| `:Cmdlog import path`      | Merges favorites from JSON                                 |

Full descriptions in [docs/commands.md](docs/commands.md).

---

## Inside a picker

`<CR>` inserts the selected command into the command-line without running it,
`<Tab>` toggles it as a favorite, `<C-x>` deletes it from its source, `<C-s>`
rotates to the next picker keeping what you typed. A legend of the active keys
sits in the Telescope prompt title, and the full set — with the config key for
each — is in [docs/BINDINGS.md](docs/BINDINGS.md).

These keys are Telescope's; under `picker = "fzf"` only `<CR>` is bound, and
it *runs* the command rather than inserting it.

---

## Documentation

Start at [docs/README.md](docs/README.md), which says what is where and which
question each page answers.

- [Installation](docs/installation.md) — every package manager, and what lazy-loading costs.
- [Configuration](docs/configuration.md) — every option, its default, and where it is read.
- [Commands](docs/commands.md) — each `:Cmdlog` subcommand and its arguments.
- [Bindings](docs/BINDINGS.md) — every user command, in-picker keymap and autocmd.
- [Features](docs/FEATURES/README.md) — one page per part of the plugin, and why each has its shape.
- [Workflow](docs/WORKFLOW.md) — how the subcommands, favorites, tags and scoping combine into a habit.

---

## Feedback

Bugs, feature ideas and usage questions are welcome in the
[issue tracker](https://github.com/StefanBartl/cmdlog.nvim/issues); anything
more open-ended fits a
[discussion](https://github.com/StefanBartl/cmdlog.nvim/discussions). If you
want to work on the plugin itself, start at
[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md).

---

## License

MIT — see [LICENSE](LICENSE).
