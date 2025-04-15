# nvim-cmdlog

A lightweight, modern Neovim plugin to interactively view, search, and reuse command-line mode (`:`) history using Telescope.

- ⚠️ This is an **alpha version** – features and APIs are subject to change.

---

## Features

![Cmdlog Picker UI](./docs/assets/Cmdlog-Picker-UI.png)

- Interactive listing of `:` command history using [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- Select an entry to insert it into the command-line (without auto-execution)
- Mark and manage favorites (`~/.local/share/nvim-cmdlog/favorites.json`)
- Planned:
  - Delete single history entries
  - Project-based history (per `.git` root)
  - Integration with `which-key`
  - Highlighting for error-prone commands
  - Preview view for commands like `:edit`, `:term`

![Favorites Picker](./docs/assets/Cmdlog-Favorites-Picker.png)

---

## Installation (with Lazy.nvim)

You can install `nvim-cmdlog` like this:

### Load immediately (recommended for most setups)

This ensures all commands (:Cmdlog, :CmdlogFavorites, etc.) are available without delay.

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = false, -- loads immediately
  dependencies = {
    "nvim-lua/plenary.nvim",   -- Required for JSON + file handling
    "nvim-telescope/telescope.nvim", -- Required for UI
  },
  config = function()
    require("cmdlog").setup()
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
  cmd = { "Cmdlog", "CmdlogFavorites" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("cmdlog").setup()
  end,
}
```

#### Option 2: Lazy-load via keybindings

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = true,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
  },
  keys = {
    { "<leader>cl", "<cmd>Cmdlog<CR>", desc = "Show command history" },
    { "<leader>cf", "<cmd>CmdlogFavorites<CR>", desc = "Show favorites" },
  },
  config = function()
    require("cmdlog").setup()
  end,
}
```

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
    require("cmdlog").setup()
  end,
}
```

Note: If you lazy-load the plugin, make sure to define how it should be triggered (`cmd`, `keys`, `event`, etc.), otherwise commands like `:Cmdlog` won’t be available.

---

## Dependencies

Make sure the following plugins are installed:

- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) – required for favorites functionality

---

## Usage

This plugin provides several Telescope-based pickers to explore and reuse command-line history:

| Command              | Description                                                  |
|----------------------|--------------------------------------------------------------|
| `:Cmdlog`            | Shows full `:` history, including duplicates                |
| `:CmdlogUnique`      | Shows only unique `:` commands (latest occurrence kept)     |
| `:CmdlogFavorites`   | Shows commands you've marked as favorites                   |
| `:CmdlogAll`         | Combines favorites + full history (duplicates allowed)      |
| `:CmdlogAllUnique`   | Combines favorites + history (only unique commands)         |

### Shortcuts (inside pickers)

- `<CR>`: Insert command into `:` (does not execute)
- `<C-f>`: Toggle favorite
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

This is **alpha software**. Expect changes, rough edges, and bugs.
Your feedback will help shape the future of container management in Neovim.

---
