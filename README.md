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

- **Picker Backend Options**: Choose between [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) or [fzf-lua](https://github.com/ibhagwan/fzf-lua) for the picker backend, depending on your preference.

- **Favorites Management**: Mark and manage favorite commands with ease. Your favorites are saved in the `~/.local/share/nvim-cmdlog/favorites.json` file for easy access.

- **Command Execution**: Select an entry from the history to insert it into the command-line (without auto-execution), giving you control over your workflow.

- **Command Previews**: Preview the output of various commands directly within the picker. Currently supported preview types include:
  - **`:edit <file>`**: Shows the file preview if the file is readable.
  - **`:!<shell>`**: Simulates shell command output for supported shell commands.
  - **`:term`, `:make`, `:lua`, and `:help`**: These command previews are in progress, with plans to cover more commands in the future.

- **Custom Pickers**: Developers and users can easily create their own custom pickers. A utility file, `picker_utils.lua`, abstracts much of the configuration, making it simple to extend the functionality. Comprehensive documentation on how to create and add custom pickers is available in the `/docs/` directory.

### Planned Features:
- **Delete Single History Entries**: Easily remove individual entries from your history.
- **Project-Based History**: Maintain separate command histories per Git project (`.git` root).
- **Integration with `which-key`**: Add quick key bindings and descriptions for commands within your workflow.
- **Error-Prone Command Highlighting**: Highlight commands that are prone to errors, helping you avoid mistakes.

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
