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

## Installation (with Lazy)

```lua
{
  "StefanBartl/nvim-cmdlog",
  lazy = true,
  cmd = { "Cmdlog" },
  config = function()
    require("cmdlog").setup()
  end,
}
```

- Note: Requires [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) to be installed.

---

## Usage

After installation, run `:Cmdlog` to open the interactive history picker.

You can select an entry to insert it into the command-line (it will not be executed automatically).
Favorites will be saved and persist across sessions.

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
