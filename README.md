# nvim-cmdlog

A lightweight, modern Neovim plugin to interactively view, search, and reuse command-line mode (`:`) history using Telescope.

- ⚠️ This is an **alpha version** – features and APIs are subject to change.

---

## Features

- Interactive listing of `:` command history using [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- Select an entry to insert it into the command-line (without auto-execution)
- Mark and manage favorites (`~/.local/share/nvim-cmdlog/favorites.json`)
- Planned:
  - Delete single history entries
  - Project-based history (per `.git` root)
  - Integration with `which-key`
  - Highlighting for error-prone commands
  - Preview view for commands like `:edit`, `:term`

---

Guter Punkt – wir bringen das eleganter und vollständiger unter.
Ziel: Klare Anleitung für **nicht-lazy** UND **lazy mit `event`, `cmd` oder `keys`**.

---

## Installation (with Lazy.nvim)

You can install `nvim-cmdlog` like this:

### Load immediately (recommended for most setups)

This registers all commands (`:Cmdlog`, `:CmdlogFavorites`) on startup.

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = false, -- loads immediately
  config = function()
    require("cmdlog").setup()
  end,
}
```

### Load lazily (alternative)

You can also lazy-load the plugin if you prefer:

#### Option 1: Lazy-load on specific commands

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = true,
  cmd = { "Cmdlog", "CmdlogFavorites" },
  config = function()
    require("cmdlog").setup()
  end,
}
```

#### Option 2: Lazy-load on keybinding

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = true,
  keys = {
    { "<leader>cl", "<cmd>Cmdlog<CR>", desc = "Show command history" },
    { "<leader>cf", "<cmd>CmdlogFavorites<CR>", desc = "Show favorites" },
  },
  config = function()
    require("cmdlog").setup()
  end,
}
```

#### Option 3: Lazy-load on startup event

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = true,
  event = "VeryLazy", -- or e.g. "BufReadPost"
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

## Development & Contribution

Clone this repo and symlink or add to your Neovim runtime path for local development.

---

## License

[MIT License](./LICENSE)

---

## Disclaimer

This is **alpha software**. Expect changes, rough edges, and bugs.
Your feedback will help shape the future of container management in Neovim.

---
