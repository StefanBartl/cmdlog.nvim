```
 ██████╗███╗   ███╗██████╗ ██╗      ██████╗  ██████╗
██╔════╝████╗ ████║██╔══██╗██║     ██╔═══██╗██╔════╝
██║     ██╔████╔██║██║  ██║██║     ██║   ██║██║  ███╗
██║     ██║╚██╔╝██║██║  ██║██║     ██║   ██║██║   ██║
╚██████╗██║ ╚═╝ ██║██████╔╝███████╗╚██████╔╝╚██████╔╝
 ╚═════╝╚═╝     ╚═╝╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝
                                            .nvim
```

![status](https://img.shields.io/badge/status-beta-orange.svg)
![Lazy.nvim compatible](https://img.shields.io/badge/lazy.nvim-supported-success)
![Neovim](https://img.shields.io/badge/Neovim-0.9+-success.svg)
![Lua](https://img.shields.io/badge/language-Lua-yellow.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Contributions](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)

> **Pairs well with [filetree.nvim](https://github.com/StefanBartl/filetree.nvim)** — nvim-cmdlog gives you fast recall of past `:` and shell commands, filetree.nvim gives you adapter-agnostic file-tree actions. Together they cover command reuse and file navigation in one consistent style.

🔧 Beta stage – under active development. Changes possible. Expect bugs, especially with the history feature on windows systems.

A lightweight, modern Neovim plugin to interactively view, search, and reuse command-line mode (`:`) history and shell history using Telescope (standard) ord fzf.

---

- [Features](#features)
- [Installation (with Lazy.nvim)](#installation-with-lazynvim)
  - [Load immediately](#load-immediately-recommended-for-most-setups)
  - [Load lazily (alternative)](#load-lazily-alternative)
    - [Option 1: Lazy-load on demand (command)](#option-1-lazy-load-on-demand-command)
    - [Option 2: Lazy-load via keybindings](#option-2-lazy-load-via-keybindings)
    - [Option 3: Lazy-load on specific event](#option-3-lazy-load-on-specific-event)
- [Installation (other package managers)](#installation-other-package-managers)
- [Dependencies](#dependencies)
- [Picker configuration (Telescope vs FzfLua)](#picker-configuration-telescope-vs-fzflua)
  - [When to use which picker?](#when-to-use-which-picker)
- [Usage](#usage)
  - [Cmdlog Picker Demo](#cmdlog-picker-demo)
  - [Command Syntax](#command-syntax)
  - [Commands](#commands)
  - [Shortcuts (inside pickers)](#shortcuts-inside-pickers)
- [Development](#development)
- [License](#license)
- [Disclaimer](#disclaimer)
- [Feedback](#feedback)

---

## Features

![Cmdlog Picker UI](./docs/assets/Cmdlog-Picker-UI.png)

- **Interactive command history listing**: View and search through your `:` command history interactively using [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).

- **Shell History Integration**: In addition to the standard Neovim command history, shell history for various supported shells is also included, such as:
  - `zsh`: `~/.zsh_history`
  - `bash`: `~/.bash_history`
  - `fish`: `~/.local/share/fish/fish_history`
  - `nu`: `~/.config/nushell/history.txt`
  - `ksh`: `~/.ksh_history`
  - `csh`: `~/.history`
  - pwsh  %APPDATA%\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt

- **Picker Backend Options**: Choose between [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) or [fzf-lua](https://github.com/ibhagwan/fzf-lua) for the picker backend, depending on your preference.

- **Favorites Management**: Mark and manage favorite commands with ease. Your favorites are saved in the `~/.local/share/nvim-cmdlog/favorites.json` file for easy access.

- **Command Execution**: Select an entry from the history to insert it into the command-line (without auto-execution), giving you control over your workflow.

- **Command Previews**: Preview the output of various commands directly within the picker. Currently supported preview types include:
  - **`:edit <file>`**: Shows the file preview if the file is readable.
  - **`:!<shell>`**: Simulates shell command output for supported shell commands.
  - **`:term`, `:make`, `:lua`, and `:help`**: These command previews are in progress, with plans to cover more commands in the future.

- **Custom Pickers**: Developers and users can easily create their own custom pickers. A utility file, `picker_utils.lua`, abstracts much of the configuration, making it simple to extend the functionality. Comprehensive documentation on how to create and add custom pickers is available in the `/docs/` directory.

- **Configurable & which-key aware keymaps**: Picker keymaps (`<CR>`, `<Tab>`, `<C-r>`) can be remapped or disabled, and optional normal-mode entry-point keymaps for every `:Cmdlog*` command can be enabled — each carries a `desc`, so [which-key.nvim](https://github.com/folke/which-key.nvim) picks it up automatically. See [BINDINGS.md](./docs/BINDINGS.md).

- **`:checkhealth cmdlog`**: Verifies dependencies (plenary, telescope/fzf-lua), shell-history detection, and notes directory.

- **Delete single history entries**: Press `<C-x>` (configurable) inside a picker to delete the selected command from its underlying history — Neovim `:` history via `histdel()`, or the shell history file (with a confirmation prompt, since that rewrites a file on disk).

- **Error-prone command highlighting**: Commands matching a configurable list of risky patterns (`rm -rf`, `git reset --hard`, `git push --force`, `:qa!`, ...) are highlighted with `CmdlogRiskyCommand` so you notice them before reusing them. Configurable/disableable via `risky_patterns` / `highlight_risky`.

- **Project-based favorites** *(opt-in)*: Set `project_scoped.enabled = true` to keep a separate favorites file per Git project instead of one global file. Off by default — existing favorites are unaffected.

### Planned Features:
- **Project-scoped command/shell history** (beyond favorites): the raw `:` and shell history views are still global/session-wide; only favorites are project-aware so far.

![Favorites Picker](./docs/assets/Cmdlog-Favorites-Picker.png)

---

## Installation (with Lazy.nvim)

You can install `nvim-cmdlog` like this:

### Load immediately (recommended for most setups)

This ensures all commands (:Cmdlog, :CmdlogFavorites, etc.) are available without delay.

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = false,
  dependencies = {
    "StefanBartl/lib.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- Required if you use picker = "telescope"
    "ibhagwan/fzf-lua",              -- Required if you use picker = "fzf"
  },
  config = function()
    require("cmdlog").setup({
      picker = "telescope",  -- or "fzf"
    })
  end,
}
```

### Load lazily (alternative)

You can also lazy-load the plugin if you prefer:

#### Option 1: Lazy-load on demand (command)

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = true,
  cmd = {
    "CmdlogNvimFull", "CmdlogNvim", "CmdlogFull", "Cmdlog",  -- see Note!
    "CmdlogShellFull", "CmdlogShell", "CmdlogFavorites"
  },
  dependencies = {
    "StefanBartl/lib.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "ibhagwan/fzf-lua",
  },
  config = function()
    require("cmdlog").setup({
      picker = "fzf", -- or "telescope"
    })
  end,
}
```

> **Note**: Only the commands listed here will be available for lazy-loading. Make sure to include the ones you intend to use, such as `Cmdlog`, `CmdlogFavorites`, etc. If a command is omitted, it won't work when lazy-loaded.

#### Option 2: Lazy-load via keybindings

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = true,
  keys = {
    { "<leader>cl", "<cmd>Cmdlog<CR>", desc = "Show command history" },
    { "<leader>cf", "<cmd>CmdlogFavorites<CR>", desc = "Show favorites" },
  },
  dependencies = {
    "StefanBartl/lib.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "ibhagwan/fzf-lua",
  },
  config = function()
    require("cmdlog").setup({
      picker = "telescope",
    })
  end,
}
```

---

#### Option 3: Lazy-load on specific event

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = true,
  event = "VeryLazy", -- or e.g. "BufReadPost"
  dependencies = {
    "StefanBartl/lib.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("cmdlog").setup({
      picker = "telescope",  -- or "fzf"
  })
}
```

Note: If you lazy-load the plugin, make sure to define how it should be triggered (`cmd`, `keys`, `event`, etc.), otherwise commands like `:Cmdlog` won’t be available.

---

## Installation (other package managers)

### packer.nvim

```lua
use({
  "StefanBartl/nvim-cmdlog",
  requires = {
    "StefanBartl/lib.nvim",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim", -- or "ibhagwan/fzf-lua"
  },
  config = function()
    require("cmdlog").setup({ picker = "telescope" })
  end,
})
```

### vim-plug

```vim
Plug 'StefanBartl/lib.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim' " or 'ibhagwan/fzf-lua'
Plug 'StefanBartl/nvim-cmdlog'
```

```lua
require("cmdlog").setup({ picker = "telescope" })
```

---

## Dependencies

Make sure the following plugins are installed:

- [lib.nvim](https://github.com/StefanBartl/lib.nvim) – cross-platform fs/notify helpers (required)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) – required for favorites functionality
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) (only if picker = "fzf")

---

## Picker configuration (Telescope vs FzfLua)

By default, `nvim-cmdlog` uses **Telescope** for all pickers and UI interactions.
However, you can switch to [fzf-lua](https://github.com/ibhagwan/fzf-lua) by setting:

```lua
require("cmdlog").setup({
  picker = "fzf",
})
```

| Picker                | Notes                                                                                                        |
| :-------------------- | :----------------------------------------------------------------------------------------------------------- |
| `telescope` (default) | Full feature support, including command previews (e.g., file contents for `:edit somefile.txt`)              |
| `fzf`                 | Minimal, fast UI. **Currently no preview support** for commands like `:edit`. (Planned for future versions.) |

### When to use which picker?

- **Telescope**: Recommended if you want previews, fuzzy sorting, and a richer UI experience.
- **FzfLua**: Recommended if you prefer speed, simplicity, and minimal dependencies.

| Feature                           | Telescope             | FzfLua                |
| :-------------------------------- | :-------------------- | :-------------------- |
| Fuzzy Search                      | ✅ Built-in            | ✅ Built-in            |
| Command Previews (`:edit`)        | ✅ Available           | ❌ Not available yet   |
| Favorite toggling (`<C-f>`)       | ✅ Available           | ✅ Available           |
| Performance (Speed)               | ⚡ Good                | ⚡⚡ Very fast          |
| UI Customization (Prompt, Border) | ✅ Highly customizable | ✅ Highly customizable |
| External Dependencies             | Telescope + Plenary   | Only Plenary          |

---

## Usage

This plugin provides several Telescope-based pickers to explore and reuse command-line history.

### Cmdlog Picker Demo

![Cmdlog Picker Demo](./docs/assets/Cmdlog-Picker-Demo.gif)

### Command Syntax

`{Cmdlog}{Util}[optional Full]`

### Commands

| Command            | Description                                                                  |
| ------------------ | ---------------------------------------------------------------------------- |
| `:CmdlogFavorites` | Shows commands you've marked as favorites                                    |
| `:Cmdlog`          | Combines favorites and history, showing only unique commands (no duplicates) |
| `:CmdlogFull`      | Combines favorites and full history, allowing duplicates                     |
| `:CmdlogNvim`      | Shows only unique Neovim (`:`) commands (latest occurrence kept)             |
| `:CmdlogNvimFull`  | Shows full Neovim (`:`) history, including duplicates                        |
| `:CmdlogShell`     | Shows unique shell history (latest occurrence kept)                          |
| `:CmdlogShellFull` | Shows full shell history, including duplicates                               |

---

### Shortcuts (inside pickers)

- `<CR>`: Insert command into `:` (does not execute)
- `<Tab>`: Toggle favorite
- `<C-r>`: Refresh picker

---

## Development

To develop or contribute:

1. Clone the repo:

```bash
git clone https://github.com/StefanBartl/nvim-cmdlog ~/.config/nvim/lua/plugins/nvim-cmdlog
```

2. Symlink or load manually via your plugin manager.
3. Make changes, test with :Cmdlog, submit PRs or open issues.

**Contributions are welcome** – whether it's a bugfix, feature, or idea!

---

## License

[MIT License](./LICENSE)

---

## Disclaimer

ℹ️ This plugin is under active development – some features are planned or experimental.
Expect changes in upcoming releases.

---

## Feedback

Your feedback is very welcome!

Please use the [GitHub issue tracker](https://github.com/StefanBartl/nvim-cmdlog/issues) to:
- Report bugs
- Suggest new features
- Ask questions about usage
- Share thoughts on UI or functionality

For general discussion, feel free to open a [GitHub Discussion](https://github.com/StefanBartl/nvim-cmdlog/discussions).

If you find this plugin helpful, consider giving it a ⭐ on GitHub — it helps others discover the project.

---
