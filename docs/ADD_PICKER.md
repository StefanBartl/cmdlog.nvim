# `DOCS/ADD_PICKER.md`

## How to create a new picker (nvim-cmdlog)

With the unified picker system (`picker_utils.open_picker()`), creating a new picker is simple and consistent.

### 1. Load your data

Prepare a list of entries that should be displayed.

```lua
local entries = { "command1", "command2", "command3" }
local favorites = { "command2" }
```

---

### 2. Call `picker_utils.open_picker`

Pass your entries and favorites to `open_picker`, along with picker-specific options:

```lua
local picker_utils = require("cmdlog.ui.picker_utils")

picker_utils.open_picker(entries, favorites, {
  prompt_title = ":my new picker",
  fzf_prompt = ":my new picker> ",
  attach_mappings = require("cmdlog.ui.mappings").your_mapping_function,
})
```

---

### 3. Optional: Custom actions

You can also define custom `actions` if needed (e.g., for `<C-f>` toggling, executing differently, etc.):

```lua
picker_utils.open_picker(entries, favorites, {
  prompt_title = ":example",
  fzf_prompt = ":example> ",
  actions = {
    ["default"] = function(selected)
      vim.cmd(selected[1])
    end,
  },
})
```

---

## Notes

- **Favorites** are automatically highlighted with a star (`★`) if passed correctly.
- **Telescope and fzf** backends are automatically selected based on user configuration.
- All previewers are handled consistently via `telescope-previewer.lua` and `fzf-previewer.lua`.
- All custom mappings are injected cleanly using `attach_mappings`.

---

##  Quick Checklist

| Step | Check |
|:----|:-----|
| Load entries | ✅ |
| Call `picker_utils.open_picker` | ✅ |
| Set prompt titles | ✅ |
| Define actions or mappings if needed | ✅ |

---

## Tip

If you want to reuse existing mappings (e.g., from `history_picker`), just import and reuse them!

```lua
attach_mappings = require("cmdlog.ui.mappings").show_history_picker
```

---
