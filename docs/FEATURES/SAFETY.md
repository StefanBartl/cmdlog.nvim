# Safety

The two features that exist purely to keep a picker from being the thing
that hurts you: one flags a command before you rerun it, the other keeps
a command from ever being written to disk in the first place.

## Risky command highlighting

Commands matching a configurable list of Lua patterns (`rm -rf`,
`git reset --hard`, `git push --force`, `git clean -f`/`-d`, `:qa!`,
`:wqa!`, `sudo rm`, `mkfs`, `dd if=`, ...) are highlighted with the
`CmdlogRiskyCommand` highlight group (linked to `DiagnosticError` by
default) wherever they appear in a picker, so a destructive one-liner
doesn't blend in with everything else in your history. Telescope only.

- **Module:** `cmdlog/core/risky.lua` (`is_risky`, `matching`),
  `cmdlog/ui/risky_test.lua`
- **Usercmds:** `:Cmdlog risky test <command>` — reports which patterns match
  a given command line, so the list can be tuned without guessing from
  picker colours. Added 2026-08-24; ignores `highlight_risky` (that gates
  display, not evaluation) and says so when it is off.
- **Config:** `opts.highlight_risky = true`, `opts.risky_patterns = {...}` — set either to `false`/`{}` to disable. Override the highlight group with `vim.api.nvim_set_hl(0, "CmdlogRiskyCommand", {...})` after `setup()`.

## Privacy filter (`redact_patterns`)

Commands matching a configurable list of Lua patterns (`password`,
`secret`, `token`, `Bearer`, `api[-_]?key` by default) are never
recorded to project history, usage stats, or the error log — those
stores are plaintext JSON under `stdpath("data")`, and something like
`:!curl -H "Authorization: Bearer …"` would otherwise persist the token
there forever. Checked in `core/tracker.lua` before anything is
written, so a redacted command still runs normally — it just leaves no
trace in cmdlog's own state.

- **Module:** `cmdlog/core/tracker.lua`
- **Config:** `opts.redact_patterns = {...}` (set `false` or `{}` to disable)
