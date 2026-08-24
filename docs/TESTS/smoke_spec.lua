-- cmdlog.nvim — headless smoke test (no framework, no network).
--
-- Run:
--   nvim -l docs/TESTS/smoke_spec.lua
--
-- There is no dedicated unit-test framework wired up for this plugin yet, so
-- this script covers the baseline CI gate instead: require() every module
-- (catches load-time errors, missing requires, syntax mistakes), run
-- setup(), and exercise :checkhealth. Exits non-zero on failure so it can be
-- used in CI.

-- Self-bootstrapping runtimepath: derive repo root from this file's own
-- location and pick up lib.nvim as a sibling checkout (../lib.nvim) or via
-- $LIB_NVIM_PATH/$REPOS_DIR, matching the convention used by lib.nvim's
-- other dependents (pickers.nvim, mdview.nvim).
local this = debug.getinfo(1, "S").source:sub(2) -- strip leading '@'
local tests_dir = vim.fn.fnamemodify(this, ":h")
local root = vim.fn.fnamemodify(tests_dir, ":h:h") -- docs/TESTS -> repo root
vim.opt.runtimepath:append(root)

local siblings_root = vim.fn.fnamemodify(root, ":h")
if vim.env.REPOS_DIR and vim.fn.isdirectory(vim.env.REPOS_DIR) == 1 then
  siblings_root = vim.env.REPOS_DIR
end

local lib = siblings_root .. "/lib.nvim"
if vim.env.LIB_NVIM_PATH and vim.fn.isdirectory(vim.env.LIB_NVIM_PATH) == 1 then
  lib = vim.env.LIB_NVIM_PATH
end
if vim.fn.isdirectory(lib) == 1 then vim.opt.runtimepath:append(lib) end

-- Optional: telescope.nvim (+ its own plenary.nvim dependency), if checked
-- out as a sibling -- see optional_telescope_modules below.
for _, name in ipairs({ "telescope.nvim", "plenary.nvim" }) do
  local dir = siblings_root .. "/" .. name
  if vim.fn.isdirectory(dir) == 1 then vim.opt.runtimepath:append(dir) end
end

local passed, failed = 0, 0
local function check(name, cond, detail)
  if cond then
    passed = passed + 1
    print("  ok   " .. name)
  else
    failed = failed + 1
    print("  FAIL " .. name .. (detail and ("  -> " .. detail) or ""))
  end
end

-- ── require() every module ──────────────────────────────────────────────────
local modules = {
  "cmdlog",
  "cmdlog.@types",
  "cmdlog.bindings",
  "cmdlog.bindings.autocmds",
  "cmdlog.bindings.keymaps",
  "cmdlog.bindings.picker_mappings",
  "cmdlog.bindings.usrcmds",
  "cmdlog.config",
  "cmdlog.config.DEFAULTS",
  "cmdlog.core.errors",
  "cmdlog.core.extra_files",
  "cmdlog.core.favorites",
  "cmdlog.core.favorite_notes",
  "cmdlog.core.history",
  "cmdlog.core.project_history",
  "cmdlog.core.risky",
  "cmdlog.core.shell",
  "cmdlog.core.stats",
  "cmdlog.core.store",
  "cmdlog.core.tags",
  "cmdlog.core.tracker",
  "cmdlog.core.utils",
  "cmdlog.health",
  "cmdlog.integrations.which_key",
  "cmdlog.ui.all_picker",
  "cmdlog.ui.all_unique_picker",
  "cmdlog.ui.cycle",
  "cmdlog.ui.favorites_picker",
  "cmdlog.ui.fzf-previewer",
  "cmdlog.ui.history_picker",
  "cmdlog.ui.history_unique_picker",
  "cmdlog.ui.lua_picker",
  "cmdlog.ui.mappings",
  "cmdlog.ui.note_popup",
  "cmdlog.ui.picker_utils",
  "cmdlog.ui.project_picker",
  "cmdlog.ui.shell_picker",
  "cmdlog.ui.shell_unique_picker",
  "cmdlog.ui.stats_picker",
  "cmdlog.ui.telescope-previewer",
}

-- Modules that only load when telescope.nvim is present (lazily required by
-- their callers, never at plugin-setup time -- see cmdlog.ui.picker_utils).
-- When telescope isn't on the runtimepath (e.g. a bare CI lint job), treat
-- that specific failure as a skip rather than a hard failure.
local optional_telescope_modules = {
  ["cmdlog.ui.telescope-previewer"] = true,
}

local skipped = 0
for _, modname in ipairs(modules) do
  local ok, err = pcall(require, modname)
  if
    not ok
    and optional_telescope_modules[modname]
    and tostring(err):match("module 'telescope")
  then
    skipped = skipped + 1
    print("  skip " .. modname .. "  (telescope.nvim not on runtimepath)")
  else
    check("require(" .. modname .. ")", ok, err)
  end
end

-- ── setup() with defaults ───────────────────────────────────────────────────
do
  local ok, err = pcall(function()
    require("cmdlog").setup({})
  end)
  check("cmdlog.setup({})", ok, err)
end

do
  local config = require("cmdlog.config")
  check("config.options.picker default", config.options.picker == "telescope")
  check("config.options.mappings.enabled default", config.options.mappings.enabled == true)
end

-- ── bindings catalog ─────────────────────────────────────────────────────────
do
  local ok, catalog = pcall(function()
    return require("cmdlog.bindings").catalog()
  end)
  check("bindings.catalog()", ok and type(catalog) == "table", catalog)
  if ok then check("bindings.catalog().usrcmds non-empty", #catalog.usrcmds > 0) end
end

-- ── core.utils pure functions ───────────────────────────────────────────────
do
  local utils = require("cmdlog.core.utils")
  local reversed = utils.reverse_list({ "a", "b", "c" })
  check(
    "utils.reverse_list",
    reversed[1] == "c" and reversed[2] == "b" and reversed[3] == "a",
    vim.inspect(reversed)
  )

  local deduped = utils.deduplicate_list({ "a", "b", "a", "c", "b" })
  check("utils.deduplicate_list", #deduped == 3, vim.inspect(deduped))
end

-- ── picker_utils.section_dividers (pure function, no telescope needed) ─────
do
  local picker_utils = require("cmdlog.ui.picker_utils")

  local single_block = picker_utils.section_dividers({
    { label = "favorites", count = 0 },
    { label = "nvim history", count = 3 },
    { label = "shell history", count = 0 },
  })
  check("section_dividers: nil for a single non-empty block", single_block == nil)

  local two_blocks = picker_utils.section_dividers({
    { label = "nvim history", count = 2 },
    { label = "shell history", count = 3 },
  })
  check(
    "section_dividers: divider at each block start",
    two_blocks ~= nil
      and #two_blocks == 2
      and two_blocks[1].at == 1
      and two_blocks[1].label == "nvim history"
      and two_blocks[2].at == 3
      and two_blocks[2].label == "shell history",
    vim.inspect(two_blocks)
  )
end

-- ── core.favorite_notes round trip (isolated path, doesn't touch real data) ─
do
  local config = require("cmdlog.config")
  config.options.favorite_notes_path = vim.fn.tempname() .. "-cmdlog-favorite-notes.json"
  local favorite_notes = require("cmdlog.core.favorite_notes")

  check("favorite_notes.get_note: nothing set yet", favorite_notes.get_note(":w") == nil)

  favorite_notes.set_note(":w", "saves the buffer")
  check(
    "favorite_notes.set_note/get_note round trip",
    favorite_notes.get_note(":w") == "saves the buffer"
  )

  favorite_notes.set_note(":w", "")
  check("favorite_notes.set_note('') deletes the note", favorite_notes.get_note(":w") == nil)
end

-- ── core.risky: which patterns matched, not just whether any did ───────────
do
  local config = require("cmdlog.config")
  config.options.highlight_risky = true
  config.options.risky_patterns = { "rm%s+%-rf", "mkfs", "%[unfinished" }
  local risky = require("cmdlog.core.risky")

  local hits = risky.matching("sudo rm -rf /tmp/x")
  check(
    "risky.matching: reports the pattern that fired",
    #hits == 1 and hits[1] == "rm%s+%-rf",
    vim.inspect(hits)
  )
  check("risky.matching: no match returns an empty list", #risky.matching("ls -la") == 0)
  check("risky.is_risky still agrees with matching", risky.is_risky("sudo rm -rf /") == true)

  -- A malformed user pattern must exclude itself rather than break the
  -- picker that is only trying to colour a line.
  local ok_bad = pcall(risky.matching, "some [unfinished thing")
  check("risky.matching: a malformed pattern does not raise", ok_bad)

  -- highlight_risky gates display, not evaluation -- otherwise `risky test`
  -- would answer "no match" for someone who turned highlighting off.
  config.options.highlight_risky = false
  check("risky.matching ignores highlight_risky", #risky.matching("mkfs.ext4 /dev/sda") == 1)
  check("risky.is_risky honours highlight_risky", risky.is_risky("mkfs.ext4 /dev/sda") == false)
  config.options.highlight_risky = true

  local ok_report = pcall(function()
    require("cmdlog.ui.risky_test").report("sudo rm -rf /")
    require("cmdlog.ui.risky_test").report("ls")
    require("cmdlog.ui.risky_test").report("")
  end)
  check("risky_test.report: runs for match / no-match / empty", ok_report)
end

-- ── core.shell: the custom-parser escape hatch ─────────────────────────────
do
  local config = require("cmdlog.config")
  local shell = require("cmdlog.core.shell")

  local histfile = vim.fn.tempname() .. "-cmdlog-hist"
  vim.fn.writefile({ "2026-08-24|git status", "2026-08-24|ls -la" }, histfile)
  config.options.shell_history_path = histfile

  config.options.shell_history = {
    parse = function(lines)
      local out = {}
      for _, line in ipairs(lines) do
        out[#out + 1] = line:match("|(.*)$")
      end
      return out
    end,
  }

  local parsed = shell.get_shell_history()
  check(
    "shell_history.parse: used instead of the built-in parsers",
    #parsed == 2 and parsed[1] == "git status",
    vim.inspect(parsed)
  )

  -- parse without matches must refuse to delete rather than let the built-in
  -- matcher guess at a format it does not know and remove the wrong lines.
  local refused_err
  shell.delete_entry("git status", nil, function(ok, err)
    refused_err = (not ok) and err or nil
  end)
  check(
    "delete_entry: refuses when parse is set without matches",
    refused_err ~= nil and refused_err:find("matches", 1, true) ~= nil,
    tostring(refused_err)
  )

  -- With both halves, deletion works and rewrites only the matching line.
  config.options.shell_history.matches = function(line, cmd)
    return line:match("|(.*)$") == cmd
  end
  local deleted
  shell.delete_entry("git status", { skip_confirm = true }, function(ok)
    deleted = ok
  end)
  check("delete_entry: works once matches is supplied", deleted == true)
  check(
    "delete_entry: removed only the matching line",
    vim.deep_equal(vim.fn.readfile(histfile), { "2026-08-24|ls -la" }),
    vim.inspect(vim.fn.readfile(histfile))
  )

  -- A parser that raises leaves the picker empty rather than breaking it.
  config.options.shell_history = {
    parse = function()
      error("boom")
    end,
  }
  local ok_raise, raised = pcall(shell.get_shell_history)
  check("shell_history.parse: a raising parser is contained", ok_raise and #raised == 0)

  config.options.shell_history = {}
end

-- ── delete_fn contract: every picker source honours (cmd, on_done, opts) ───
--
-- Regression: the mappings call delete_fn(cmd, on_done, opts), but
-- history.delete_entry is (cmd) -> boolean and shell.delete_entry is
-- (cmd, opts, on_done). Passed straight through, the first never invoked the
-- callback (picker stayed open on a stale list) and the second raised
-- "attempt to call local 'on_done' (a nil value)". Both go through adapters
-- now; this pins the underlying signatures those adapters assume.
do
  local history = require("cmdlog.core.history")
  check(
    "history.delete_entry is synchronous and returns a boolean",
    type(history.delete_entry("nothing matches this")) == "boolean"
  )

  local shell = require("cmdlog.core.shell")
  local got
  shell.delete_entry("nothing matches this", { skip_confirm = true }, function(ok, err)
    got = { ok = ok, err = err }
  end)
  check(
    "shell.delete_entry is (cmd, opts, on_done) and always calls back",
    type(got) == "table" and got.ok == false,
    vim.inspect(got)
  )
end

-- ── :checkhealth cmdlog (smoke only -- asserts it runs without erroring) ────
do
  local ok, err = pcall(function()
    require("cmdlog.health").check()
  end)
  check("cmdlog.health.check() runs without error", ok, err)
end

print(("\n%d passed, %d failed, %d skipped"):format(passed, failed, skipped))
if failed > 0 then os.exit(1) end
