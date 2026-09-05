# Adding a picker

Every `:Cmdlog` subcommand is the same shape: load a list of command strings,
hand it to `picker_utils.open_picker()`, and let that pick the backend. A new
picker is that plus one entry in the command catalog.

Read [`lua/cmdlog/ui/lua_picker.lua`](../lua/cmdlog/ui/lua_picker.lua)
alongside this page — at thirty lines it is the whole pattern with nothing
else in it.

## 1. Load your entries

Plain strings, already deduplicated or ordered the way you want them shown.
`core/utils.process_list` does the usual filtering and `unique` pass, and
`core/favorites.load()` gives the list that decides which entries get a `★`.

```lua
local favorites = require("cmdlog.core.favorites")
local process_list = require("cmdlog.core.utils").process_list

local favs = favorites.load()
local entries = process_list(raw_lines, { unique = true })
```

Bail out with a notification rather than opening an empty picker:

```lua
if #entries == 0 then
  notify.info("No entries found")
  return
end
```

## 2. Open it

```lua
local picker_utils = require("cmdlog.ui.picker_utils")

picker_utils.open_picker(entries, favs, {
  prompt_title = ":my picker",   -- Telescope; the key legend is appended to it
  fzf_prompt = ":my picker> ",   -- fzf-lua
  attach_mappings = require("cmdlog.ui.mappings")(M.show_my_picker),
})
```

`cmdlog.ui.mappings` **is a factory, not a table of named functions** — the
module returns one function, and calling it builds the `attach_mappings`
closure for your picker:

```lua
require("cmdlog.ui.mappings")(refresh_fn, delete_fn, opts)
```

- `refresh_fn` — usually your own show function, so `<C-r>` and a favorite
  toggle can reopen the picker with fresh data.
- `delete_fn` *(optional)* — `fun(cmd, on_done, opts)`, deleting `cmd` from
  whatever source it came from. Omit it and `<C-x>` is simply not bound, which
  is what a picker with no meaningful delete target wants.
- `opts` *(optional)* — `{ tag = true, reorder = true }`, both only meaningful
  in the favorites picker: tags and manual order are stored per favorite.

Keys themselves come from `config.options.mappings`, so a user's remap or
`false` applies to your picker without you doing anything.

## 3. Optional extras

- **`label = function(entry) return "nvim" end`** appends an origin label to
  the display. Telescope only.
- **`sections = picker_utils.section_dividers(blocks)`** splices
  non-selectable `── nvim history ──` rows between origin blocks. `blocks` is
  the ordered `{ label, count }` list you concatenated `entries` from; it
  returns `nil` when fewer than two blocks are non-empty. Telescope only.
- **`actions = { default = function(selected) … end }`** replaces the fzf-lua
  action table. fzf-lua only — under `picker = "fzf"` this is the *only* hook,
  because its entries double as the value fed back to actions, which is why
  none of the decoration or the mappings above exist there.

## 4. Register the subcommand

Add one entry to `M.catalog` in
[`lua/cmdlog/bindings/usrcmds.lua`](../lua/cmdlog/bindings/usrcmds.lua):

```lua
{
  path = "mine",
  desc = "What this picker shows",
  module = "cmdlog.ui.my_picker",
  fn = "show_my_picker",
},
```

That is the whole registration. The route, its `<Tab>` completion, the
`keymaps` entry point and `require("cmdlog.bindings").catalog()` all derive
from this list — see [FEATURES/COMPOSER.md](FEATURES/COMPOSER.md). Then
document the subcommand in [commands.md](commands.md) and
[BINDINGS.md](BINDINGS.md), which are written by hand from the same catalog.
