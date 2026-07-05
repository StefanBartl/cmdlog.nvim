# Roadmap

This file outlines the planned milestones for `nvim-cmdlog`.

## Next Features

- [x] Project-based favorites (per Git root, opt-in via `project_scoped.enabled`, see [OPTIONS.md](./OPTIONS.md))
- [x] Integration with `which-key` (optional, opt-in entry-point keymaps with `desc`, see [BINDINGS.md](./BINDINGS.md))
- [x] Highlight commands with known error results (`risky_patterns` / `highlight_risky`, see [OPTIONS.md](./OPTIONS.md))
- [x] Delete single history entries (`mappings.delete`, default `<C-x>`)
- [ ] Preview pane for commands like `:edit`, `:term`

## Future Ideas

- [ ] Lua mode and shell mode history integration
- [ ] Custom categories/tags for favorites
- [ ] Command usage stats (frequency, last used)
