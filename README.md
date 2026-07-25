![status](https://img.shields.io/badge/status-beta-orange.svg)
![Lazy.nvim compatible](https://img.shields.io/badge/lazy.nvim-supported-success)
![Neovim](https://img.shields.io/badge/Neovim-0.9+-success.svg)
![Lua](https://img.shields.io/badge/language-Lua-yellow.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Contributions](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)

🔧 Beta stage – under active development. Changes possible. Expect bugs, especially with the history feature on windows systems.

# nvim-cmdlog

A lightweight, modern Neovim plugin to interactively view, search, and reuse command-line mode (`:`) history and shell history using Telescope (standard) ord fzf.

---

- [Features](#features)
- [Installation (with Lazy.nvim)](#installation-with-lazynvim)
  - [Load immediately](#load-immediately-recommended-for-most-setups)
  - [Load lazily (alternative)](#load-lazily-alternative)
    - [Option 1: Lazy-load on demand (command)](#option-1-lazy-load-on-demand-command)
    - [Option 2: Lazy-load via keybindings](#option-2-lazy-load-via-keybindings)
    - [Option 3: Lazy-load on specific event](#option-3-lazy-load-on-specific-event)
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

- **Command Previews**: Preview the output of various commands directly within the picker (Telescope only). Currently supported preview types include:
  - **`:edit <file>`**: Shows the file preview if the file is readable.
  - **`:!<shell>`**: Simulates shell command output for supported shell commands.
  - **`:term[inal] [cmd]`**: Runs `cmd` and shows its output, or notes that no static preview exists for a bare `:term`.
  - **`:help <topic>`**: Renders the help page via a headless Neovim instance.
  - **`:lua <expr>`**: Evaluates the expression in-process and shows the result.

- **Project-Based History**: `:Cmdlog project` shows command history recorded while working inside the current Git project (`.git` root). Recording starts once the plugin is set up — pre-existing history isn't retroactively attributed to a project.

- **Lua-Mode History**: `:Cmdlog lua` shows only `:lua`/`:lua=`/`:=` command history.

- **Usage Stats**: `:Cmdlog stats` shows commands sorted by usage frequency, annotated with how many times and when they were last used.

- **Known-Error Highlighting**: Commands whose last run set a Vim error message are flagged with a marker and highlight in the picker (Telescope only).

- **Favorite Tags**: Tag favorites with free-form labels (`<C-t>` in the picker) to organize them beyond a flat list.

- **which-key Integration**: Pass a `keymaps` table to `setup()` to register normal-mode keymaps for any `:Cmdlog` subcommand; descriptions show up in [which-key.nvim](https://github.com/folke/which-key.nvim) automatically when it's installed.

- **Custom Pickers**: Developers and users can easily create their own custom pickers. A utility file, `picker_utils.lua`, abstracts much of the configuration, making it simple to extend the functionality. Comprehensive documentation on how to create and add custom pickers is available in the `/docs/` directory.

### Planned Features:
- **Delete Single History Entries**: Easily remove individual entries from your history.

![Favorites Picker](./docs/assets/Cmdlog-Favorites-Picker.png)

---

## Installation (with Lazy.nvim)

You can install `nvim-cmdlog` like this:

### Load immediately (recommended for most setups)

This ensures `:Cmdlog` and all its subcommands (`:Cmdlog favorites`, etc.) are available without delay.

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = false,
  dependencies = {
    "StefanBartl/lib.nvim",          -- Required: the :Cmdlog command layer is built on it
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
  cmd = { "Cmdlog" },
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

> **Note**: All seven pickers live under the single `:Cmdlog` command now
> (`:Cmdlog`, `:Cmdlog favorites`, `:Cmdlog nvim`, ...), so `cmd = { "Cmdlog" }`
> covers every one of them for lazy-loading — no need to list each variant.

#### Option 2: Lazy-load via keybindings

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = true,
  keys = {
    { "<leader>cl", "<cmd>Cmdlog<CR>", desc = "Show command history" },
    { "<leader>cf", "<cmd>Cmdlog favorites<CR>", desc = "Show favorites" },
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

## Dependencies

Make sure the following plugins are installed:

- [lib.nvim](https://github.com/StefanBartl/lib.nvim) – required: the `:Cmdlog` command tree is built on `lib.nvim.usercmd.composer`
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
| Known-error highlighting          | ✅ Available           | ❌ Not available       |
| Performance (Speed)               | ⚡ Good                | ⚡⚡ Very fast          |
| UI Customization (Prompt, Border) | ✅ Highly customizable | ✅ Highly customizable |
| External Dependencies             | Telescope + Plenary   | Only Plenary          |

---

## Usage

This plugin provides several Telescope-based pickers to explore and reuse command-line history.

### Cmdlog Picker Demo

![Cmdlog Picker Demo](./docs/assets/Cmdlog-Picker-Demo.gif)

### Command Syntax

`:Cmdlog [subcommand]` — built via [`lib.nvim.usercmd.composer`](https://github.com/StefanBartl/lib.nvim),
with `<Tab>` completion on the subcommand. Bare `:Cmdlog` (no subcommand)
keeps its original meaning.

### Commands

| Command                | Description                                                                  |
| ----------------------- | ---------------------------------------------------------------------------- |
| `:Cmdlog`               | Combines favorites and history, showing only unique commands (no duplicates) |
| `:Cmdlog favorites`     | Shows commands you've marked as favorites                                    |
| `:Cmdlog full`          | Combines favorites and full history, allowing duplicates                     |
| `:Cmdlog nvim`          | Shows only unique Neovim (`:`) commands (latest occurrence kept)             |
| `:Cmdlog nvim-full`     | Shows full Neovim (`:`) history, including duplicates                        |
| `:Cmdlog shell`         | Shows unique shell history (latest occurrence kept)                          |
| `:Cmdlog shell-full`    | Shows full shell history, including duplicates                               |
| `:Cmdlog project`       | Shows history recorded while inside the current Git project                  |
| `:Cmdlog lua`           | Shows only Lua-mode command history (`:lua`, `:lua=`, `:=`)                   |
| `:Cmdlog stats`         | Shows commands sorted by usage frequency                                     |

---

### Shortcuts (inside pickers)

- `<CR>`: Insert command into `:` (does not execute)
- `<Tab>`: Toggle favorite
- `<C-r>`: Refresh picker
- `<C-t>` (Telescope) / `ctrl-t` (fzf-lua): Tag the selected favorite (favorites picker only)

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
