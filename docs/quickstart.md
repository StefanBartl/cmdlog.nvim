# Quickstart

The first thing to run after installing is the bare command — favorites and
Neovim `:` history combined, deduplicated:

```vim
:Cmdlog
```

From there, narrow it, or ask a different question of the same corpus:

```vim
:Cmdlog shell              " shell history only
:Cmdlog project            " only what was typed inside this Git root
:Cmdlog stats              " sorted by how often you actually ran it
:Cmdlog favorites          " what you marked with <Tab>
```

Verify your setup any time with:

```vim
:checkhealth cmdlog
```

Every subcommand and its arguments are in [commands.md](commands.md); how
they combine into a daily habit is in [WORKFLOW.md](WORKFLOW.md).
