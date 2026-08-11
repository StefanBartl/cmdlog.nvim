# cmdlog.nvim features

Grouped by what part of the plugin they belong to, not by how recently they
were added. `COMPOSER.md` covers the `:Cmdlog <subcommand>` command surface
itself; `HISTORY.md` covers the different sources a picker can show;
`FAVORITES.md` covers everything about marking, tagging and moving
commands between machines; `PICKER.md` covers the picker UI itself
(backends, previews, the notes side window); `SAFETY.md` covers the two
things that exist purely to keep you from hurting yourself or leaking a
secret.

Every subcommand referenced below comes straight from
[`lua/cmdlog/bindings/usrcmds.lua`](../../lua/cmdlog/bindings/usrcmds.lua),
the single source of truth for the `:Cmdlog` command tree.
