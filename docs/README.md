# cmdlog.nvim documentation

What is here, and which question each page answers. [The README](../README.md)
is the short version of all of it.

## Using it

| Page | Answers |
| --- | --- |
| [COMMANDS.md](COMMANDS.md) | Every `:Cmdlog` subcommand and its arguments — one command with `<Tab>` completion, built on `lib.nvim`'s usercmd composer |
| [BINDINGS.md](BINDINGS.md) | Every user command, in-picker keymap and autocmd this plugin registers, and how to inspect the live set at runtime |
| [OPTIONS.md](OPTIONS.md) | How configuration is structured, merged and read — the defaults, the merge order, and where each option is consumed |
| [WORKFLOW.md](WORKFLOW.md) | The different question: once ten subcommands, favorites, tags, project scoping and stats all exist, how do they combine into something you actually reach for |

## Why it is the way it is

| Page | Answers |
| --- | --- |
| [FEATURES/](FEATURES/README.md) | One page per part of the plugin — the command surface, the history sources, favorites and tags, the picker UI, and the two safety features — grouped by what they belong to rather than by when they arrived |

## Working on it

| Page | Answers |
| --- | --- |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development setup and what is expected of a change |
| [ADD_PICKER.md](ADD_PICKER.md) | How to add a picker, which is the one extension point with a recipe: `picker_utils.open_picker()` and what it wants from you |
