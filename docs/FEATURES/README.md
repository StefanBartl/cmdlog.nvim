# cmdlog.nvim features

Grouped by what part of the plugin they belong to, not by how recently they
were added.

- **[COMPOSER.md](COMPOSER.md)** — the `:Cmdlog <subcommand>` command surface
  itself: how the tree is built and completed.
- **[HISTORY.md](HISTORY.md)** — the different sources a picker can show, and
  what each one knows that the others do not.
- **[FAVORITES.md](FAVORITES.md)** — marking, tagging, and moving commands
  between machines.
- **[PICKER.md](PICKER.md)** — the picker UI: the backends it can run on and
  what the preview shows.
- **[SAFETY.md](SAFETY.md)** — the two things that exist purely to keep you
  from hurting yourself or leaking a secret.

Every subcommand referenced below comes straight from
[`lua/cmdlog/bindings/usrcmds.lua`](../../lua/cmdlog/bindings/usrcmds.lua),
the single source of truth for the `:Cmdlog` command tree.
