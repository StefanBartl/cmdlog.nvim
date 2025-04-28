# Options Workflow for nvim-cmdlog

This document describes how configuration options are structured, merged, and accessed within the `nvim-cmdlog` plugin.

## Overview

- All default options are stored centrally in a table called `default_config`.
- When a user calls `setup({ ... })`, their configuration is merged with the defaults.
- The merged configuration is available globally via `M.options`.
- No option is mandatory for the user to set; defaults are always applied automatically.

---

## How Configuration Works

### Default Options

Defaults are defined once in `config.lua` like this:

```lua
local default_config = {
  favorites_path = vim.fn.stdpath("data") .. "/nvim-cmdlog/favorites.json",
  picker = "telescope", -- or "fzf"
  shell_history_path = "default", -- or custom shell history file path
}
```

The plugin ensures that `M.options` is initialized with a deep copy of `default_config`.

### User Setup

When the user calls:

```lua
require("cmdlog").setup({
  picker = "fzf",
})
```

internally the plugin merges:

- `default_config`
- and the user's `user_config`

using `vim.tbl_deep_extend("force", {}, default_config, user_config or {})`.

Any missing options are automatically filled with their defaults.

---

## Best Practices for Adding New Options

When introducing a new option:

1. **Always add it to `default_config`** with a sensible default value.
2. **Never modify `M.options` directly** outside of `setup()`.
3. **Access options only through `config.options.XYZ`** within the plugin code.
4. **Document the new option** with a brief comment in `default_config`.

Example:

```lua
local default_config = {
  preview_layout = "vertical", -- Layout of the previewer ("vertical" or "horizontal")
}
```

---

## Why This Approach?

- Ensures stability even if the user provides no configuration.
- Protects against missing or invalid fields (`nil`, `v:null`).
- Makes it easier to extend the plugin with new features.
- Keeps the internal state predictable and easy to debug.

---

## Notes

- Always validate critical options if they affect important plugin behavior (e.g., `picker` must be `"telescope"` or `"fzf"`).
- If necessary, fallback gracefully to defaults inside feature implementations.
- Do not rely on the presence of optional fields unless you have defined a clear default.

---

# Summary

| Principle | Rule |
|:----------|:-----|
| Default configuration | Stored in `default_config` |
| Merging user options | Handled in `setup()` |
| Accessing options | Only via `config.options.XYZ` |
| Adding new options | Add to `default_config` with sensible defaults |

---
