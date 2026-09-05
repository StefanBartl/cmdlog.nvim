# Contributing

Thanks for your interest in contributing to `cmdlog.nvim`.

## Development setup

1. Clone the repository:
   ```sh
   git clone https://github.com/StefanBartl/cmdlog.nvim.git
   ```
2. Point your plugin manager at the clone instead of the GitHub name — with
   lazy.nvim, `dir = "/path/to/cmdlog.nvim"` in place of the repo string.
   `lib.nvim` still has to be installed; the plugin does not run without it.
3. Restart, run `:checkhealth cmdlog`, then `:Cmdlog` to see your changes.

Style is enforced by `stylua.toml` and `.luacheckrc`, and CI runs both
(`.github/workflows/ci.yml`) alongside the smoke test in `TESTS/`.

## Guidelines

- Keep changes modular, and document them where the docs already cover the
  area — [docs/README.md](README.md) says which page owns which question.
- Prefer descriptive commit messages that say *why*.
- Follow the surrounding Lua idioms; annotate public functions for LuaLS.

## Adding a configuration option

Configuration has one source of truth, and the rules exist so it stays that
way:

1. **Add the default to `lua/cmdlog/config/DEFAULTS.lua`**, with a comment
   saying why it has that value — that comment is what
   [configuration.md](configuration.md) is written from.
2. **Add the field to `lua/cmdlog/@types/init.lua`** so LuaLS can check it.
3. **Read it only as `config.options.<name>`.** Never mutate `M.options`
   outside `setup()`; nothing else in the plugin expects it to change.
4. **Validate anything load-bearing** (`picker` must be `"telescope"` or
   `"fzf"`) and fall back to the default rather than failing, so a typo
   degrades instead of breaking the picker.
5. **Document it** in [configuration.md](configuration.md), and in
   [`doc/cmdlog.txt`](../doc/cmdlog.txt) if it belongs in the help file's
   option list.

## Adding a picker

`picker_utils.open_picker()` is the one extension point with a recipe —
see [add_picker.md](add_picker.md).

## Reporting issues

Please provide:

- Neovim version (`nvim --version`)
- Operating system, and your shell if the report touches shell history
- `:checkhealth cmdlog` output
- Clear steps to reproduce
- Optionally a screenshot or a short recording
