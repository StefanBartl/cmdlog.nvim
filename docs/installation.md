# Installation

Requirements, the specs for every package manager, and the one decision you
have to make while installing: which picker backend to pull in.

## Requirements

- Neovim **0.9+**
- [lib.nvim](https://github.com/StefanBartl/lib.nvim) — **required**. The
  `:Cmdlog` command tree is built on `lib.nvim.bindings.usercmd.composer`,
  and the cross-platform fs/notify/job helpers come from there too.
- One picker backend:
  - [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) — only
    if `picker = "telescope"` (the default)
  - [fzf-lua](https://github.com/ibhagwan/fzf-lua) — only if `picker = "fzf"`

Install the backend you configure, not both. `:checkhealth cmdlog` reports a
missing one as an error.

## Which backend

`telescope` is the default and has the fuller feature set: previews, risky-
and known-error highlighting, `<C-s>` cycling, and every in-picker keymap
(`<Tab>` to favorite, `<C-x>` to delete, `<C-t>` to tag). `fzf` is the faster,
more minimal option — under it exactly one action is bound, `<CR>`, which
*runs* the selected command; previews work on Linux and macOS but not on
Windows.

Everything else is identical: `picker` changes how a picker renders, never
which subcommands exist. Details in
[FEATURES/PICKER.md](FEATURES/PICKER.md) and
[WORKFLOW.md](WORKFLOW.md#telescope-vs-fzf-lua-pick-based-on-what-you-actually-use-pickers-for).

## lazy.nvim

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

`lazy = false` is the recommended form, and the next section is why.

### Lazy-loading costs you the history it is meant to show

`setup()` starts the `CmdlineLeave` tracker that records every `:` command —
that recording *is* the plugin. A `cmd` or `keys` trigger means the tracker
starts at the moment you first ask for the history, so everything you typed
before that was never recorded. It affects `:Cmdlog project`, `:Cmdlog stats`
and the known-error markers; Neovim's own `:` history and your shell history
are read live and are unaffected.

If you want a lazy trigger anyway, use an event — it fires early enough that
almost nothing is lost:

```lua
{
  "StefanBartl/cmdlog.nvim",
  lazy = true,
  event = "VeryLazy", -- or e.g. "BufReadPost"
  dependencies = {
    "StefanBartl/lib.nvim",
    "nvim-telescope/telescope.nvim",
  },
  opts = {},
}
```

On a command or a key trigger, accept the gap knowingly:

```lua
{
  "StefanBartl/cmdlog.nvim",
  lazy = true,
  cmd = { "Cmdlog" },
  -- or: keys = { { "<leader>cl", "<cmd>Cmdlog<CR>", desc = "Command history" } },
  dependencies = {
    "StefanBartl/lib.nvim",
    "nvim-telescope/telescope.nvim",
  },
  opts = {},
}
```

Every picker lives under the single `:Cmdlog` verb (`:Cmdlog favorites`,
`:Cmdlog nvim`, …), so `cmd = { "Cmdlog" }` covers all of them — there is no
list of variants to keep in sync. And a lazy plugin with no trigger at all is
a plugin that never loads: `:Cmdlog` will not exist.

## packer.nvim

```lua
use({
  "StefanBartl/cmdlog.nvim",
  requires = {
    "StefanBartl/lib.nvim",
    "nvim-telescope/telescope.nvim", -- or "ibhagwan/fzf-lua"
  },
  config = function()
    require("cmdlog").setup({ picker = "telescope" })
  end,
})
```

## vim-plug

```vim
Plug 'StefanBartl/lib.nvim'
Plug 'nvim-telescope/telescope.nvim' " or 'ibhagwan/fzf-lua'
Plug 'StefanBartl/cmdlog.nvim'
```

```lua
require("cmdlog").setup({ picker = "telescope" })
```

## Verifying

```
:checkhealth cmdlog
```

Checks the Neovim version, that `lib.nvim` is present, that the *configured*
backend is installed, and whether a shell history file was detected. Then open
`:Cmdlog` — bare, no subcommand — and you should see your recent `:` commands.

Next: [configuration.md](configuration.md) for every option and its default.
