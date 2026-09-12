# Integrations

Third-party plugins cmdlog notices when installed, and does nothing without.

## which-key.nvim

If `which-key.nvim` is installed, cmdlog feeds the same specs used for
`opts.keymaps` entry-points through `wk.add()`, so they also show up in
which-key's own registry/tree view. This adds no keymaps of its own — the
actual `vim.keymap.set` calls happen exactly once, in
`cmdlog.bindings.keymaps.register()`, already carrying a `desc` that
which-key v3+ would pick up on its own; the integration is only about
registry visibility. No-op when which-key is not installed.

- **Module:** [`cmdlog/integrations/which_key.lua`](../lua/cmdlog/integrations/which_key.lua)
- **Config:** `opts.keymaps` — see [configuration.md](configuration.md)
