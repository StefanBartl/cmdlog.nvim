# Roadmap

This file outlines the planned milestones for `nvim-cmdlog`.

## Next Features

- [x] Project-based history (per Git root) — `:Cmdlog project`, see `core/project_history.lua`
- [x] Integration with `which-key` — `keymaps` setup option, see `integrations/which_key.lua`
- [x] Highlight commands with known error results — Telescope-only, see `core/errors.lua`
- [x] Preview pane for commands like `:edit`, `:term` — `:help` and `:lua` also covered now

## Future Ideas

- [x] Lua mode and shell mode history integration — `:Cmdlog lua` (shell was already covered by `:Cmdlog shell`)
- [x] Custom categories/tags for favorites — `<C-t>`/`ctrl-t` in the favorites picker, see `core/tags.lua`
- [x] Command usage stats (frequency, last used) — `:Cmdlog stats`, see `core/stats.lua`
