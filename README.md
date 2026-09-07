> **Beta stage — active development.** This repository is past its first shape and in
> active use, but the surface is not frozen: breaking changes are still possible. Pin a
> commit or tag if you depend on it.

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
![Status](https://img.shields.io/badge/status-beta-orange)

Interactively view, search and reuse your Neovim command-line (`:`) history and
your shell history, through Telescope or fzf-lua.

Commands are inserted into the command-line, never executed for you — this is
recall, not automation.

![Cmdlog Picker UI](./docs/assets/Cmdlog-Picker-UI.png)

---

## Table of contents

- [Documentation](#documentation)
- [What it does](#what-it-does)
- [Around it](#around-it)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quickstart](#quickstart)
- [What you get with the defaults](#what-you-get-with-the-defaults)
- [Inside a picker](#inside-a-picker)
- [Health check](#health-check)
- [Contributing](#contributing)
- [Feedback](#feedback)
- [License](#license)

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
- [Adding a picker backend](docs/add_picker.md) — what a third front end would have to implement.
- [Contributing](docs/CONTRIBUTING.md) — ground rules and project layout.

`:help cmdlog` is the same reference inside the editor.

---

## What it does

Your `:` history and your shell history are two separate, half-usable stores:
one is capped and dies with the session, the other lives in a file your editor
cannot see. cmdlog reads both, puts them in one picker, and then adds the parts
neither has — favorites that persist, per-project scoping, usage counts, and a
warning before you re-run something that ended badly last time.

![Cmdlog Picker Demo](./docs/assets/Cmdlog-Picker-Demo.gif)

- **Neovim and shell history in one list** — `zsh`, `bash`, `fish`, `nu`, `ksh`,
  `csh` and PowerShell history files are detected per shell; entries in the
  combined pickers are labelled by origin and separated by divider rows.
- **Favorites and tags, persisted** — `<Tab>` marks, `<C-t>` tags, `<C-z>` undoes,
  `<C-Up>`/`<C-Down>` reorder; `:Cmdlog export`/`import` moves the list between
  machines.
- **Project-scoped history and favorites** — history recorded inside the current
  Git root, and optionally a separate favorites file per project.
- **Usage stats** — commands sorted by how often you actually ran them, annotated
  with the last use.
- **Risky-command highlighting** — `rm -rf`, `git reset --hard`, `:qa!` and
  friends stand out before you reuse them; the pattern list is yours to tune, and
  `:Cmdlog risky test <cmd>` says which pattern fired.
- **Known-error markers** — a command whose last run set an error message is
  flagged with `✗`.
- **Privacy filter** — commands matching `password`, `token`, `Bearer`, … are
  never written to cmdlog's own plaintext stores.
- **Previews** — `:edit` shows the file; `:help`, `:lua`, `:!` and `:term` show
  what *would* run, and only actually run it if you opt in with
  `preview_execute = true`.
- **Deleting entries** — `<C-x>` removes a command from its real source, be that
  Neovim's `:` history or the shell history file.
- **Your own history files** — `extra_files` folds arbitrary plain-text command
  lists in as read-only sources.
- **Configurable keys, which-key aware** — every in-picker key is remappable or
  disableable, and optional normal-mode entry points carry a `desc`.

One page per feature, with the reasoning behind each, in
[docs/FEATURES/README.md](docs/FEATURES/README.md).

Expect bugs, especially around shell history on Windows.

![Favorites Picker](./docs/assets/Cmdlog-Favorites-Picker.png)

---

## Around it

> **[pickers.nvim](https://github.com/StefanBartl/pickers.nvim)** — the general
> fuzzy-picker surface over files, buffers and symbols; cmdlog is the one over
> what you already typed. Same "telescope or fzf-lua, your choice" style,
> different corpus.
>
> **[filetree.nvim](https://github.com/StefanBartl/filetree.nvim)** — command
> reuse and file navigation are the two halves of not retyping things.
>
> Both are soft: without them everything else works unchanged.
> [lib.nvim](https://github.com/StefanBartl/lib.nvim) and one picker backend are
> the real dependencies — see [Requirements](#requirements).

---

## Requirements

| | |
| --- | --- |
| Neovim | **0.9+** |
| [lib.nvim](https://github.com/StefanBartl/lib.nvim) | required — the `:Cmdlog` command tree and the shared UI kit |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) **or** [fzf-lua](https://github.com/ibhagwan/fzf-lua) | required — one picker backend. Telescope is the default and the one with the full key set |

Optional, each detected at runtime and degrading to nothing when absent:

| | |
| --- | --- |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Labels for the optional normal-mode entry points |
| A shell with a plain-text history file | `zsh`, `bash`, `fish`, `nu`, `ksh`, `csh`, PowerShell — without one, `:Cmdlog shell` is simply empty |

---

## Installation

```lua
-- lazy.nvim
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

`lazy = false` is deliberate: `setup()` starts the tracker that records your `:`
commands, so a `cmd`/`keys` trigger costs you everything typed before the first
`:Cmdlog`. Other package managers, the lazy-loading variants and the backend
comparison are in [docs/installation.md](docs/installation.md).

---

## Quickstart

Open the combined picker — favorites plus history, deduplicated:

```vim
:Cmdlog
```

Then narrow it, or ask a different question of the same corpus:

```vim
:Cmdlog shell              " shell history only
:Cmdlog project            " only what was typed inside this Git root
:Cmdlog stats              " sorted by how often you actually ran it
:Cmdlog favorites          " what you marked with <Tab>
```

Verify your setup any time with:

```vim
:checkhealth cmdlog
```

---

## What you get with the defaults

One verb, `:Cmdlog [subcommand]`, with `<Tab>` completion. Full descriptions in
[docs/commands.md](docs/commands.md).

| Command | Shows |
| --- | --- |
| `:Cmdlog` | Favorites and history combined, deduplicated |
| `:Cmdlog full` | The same, with duplicates |
| `:Cmdlog nvim` / `:Cmdlog nvim-full` | Neovim `:` history, without / with duplicates |
| `:Cmdlog shell` / `:Cmdlog shell-full` | Shell history, without / with duplicates |
| `:Cmdlog favorites` | Commands you marked with `<Tab>` |
| `:Cmdlog project` | History recorded inside the current Git project |
| `:Cmdlog lua` | Lua-mode history only (`:lua`, `:lua=`, `:=`) |
| `:Cmdlog stats` | Commands sorted by usage frequency |
| `:Cmdlog risky test <cmd>` | Which `risky_patterns` match a given command line |
| `:Cmdlog export [path]` / `:Cmdlog import path` | Move favorites between machines as JSON |

---

## Inside a picker

`<CR>` inserts the selected command into the command-line without running it,
`<Tab>` toggles it as a favorite, `<C-x>` deletes it from its source, `<C-s>`
rotates to the next picker keeping what you typed. A legend of the active keys
sits in the Telescope prompt title, and the full set — with the config key for
each — is in [docs/BINDINGS.md](docs/BINDINGS.md).

These keys are Telescope's. Under `picker = "fzf"` only `<CR>` is bound, and it
*runs* the command rather than inserting it.

---

## Health check

```vim
:checkhealth cmdlog
```

Reports which picker backend resolved, which shell history file was detected and
whether it is readable, and where the favorites store lives.

---

## Contributing

Clone the repository and either symlink it or add it to your runtime path.
[docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) has the ground rules and the project
layout; [docs/add_picker.md](docs/add_picker.md) walks what a third picker
backend would have to implement.

Pull requests very welcome.

---

## Feedback

Your feedback is very welcome. Use the
[issue tracker](https://github.com/StefanBartl/cmdlog.nvim/issues) to report
bugs, suggest features or ask usage questions; anything more open-ended fits a
[discussion](https://github.com/StefanBartl/cmdlog.nvim/discussions).

If you find this plugin useful, a ⭐ on GitHub supports its development.

---

## License

MIT — see [LICENSE](LICENSE).
