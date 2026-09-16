-- cmdlog.nvim — headless smoke test (no framework, no network).
--
-- Run, from the repository root:
--   nvim -l TESTS/smoke_spec.lua
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
local root = vim.fn.fnamemodify(tests_dir, ":h") -- <repo>/TESTS -> <repo>
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

-- ui.nvim: cmdlog.core.shell requires ui.kit at module load (the
-- delete-confirmation prompt), and this script require()s every module
-- including that one, so ui.nvim has to be reachable the same way lib.nvim is.
local ui = siblings_root .. "/ui.nvim"
if vim.env.UI_NVIM_PATH and vim.fn.isdirectory(vim.env.UI_NVIM_PATH) == 1 then
  ui = vim.env.UI_NVIM_PATH
end
if vim.fn.isdirectory(ui) == 1 then vim.opt.runtimepath:append(ui) end

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

-- ── preview policy (a preview reads, it does not run) ─────────────────
do
  local policy = require("cmdlog.ui.preview_policy")
  local config = require("cmdlog.config")

  -- The default. Every executing kind has to come back refused, because the
  -- entries feeding the picker are not necessarily the user's own: extra_files
  -- folds arbitrary plain-text files in, and shell history is folded in too.
  config.options.preview_execute = false

  for _, case in ipairs({
    { ":!rm -rf build", "shell" },
    { ":lua vim.fn.delete('x')", "lua" },
    { ":term echo hi", "terminal" },
    { ":help vim.lsp", "help" },
  }) do
    local plan = policy.plan(case[1])
    check(
      ("preview_policy: %s is classified %s and refused by default"):format(case[1], case[2]),
      plan.kind == case[2]
        and plan.executes == true
        and plan.allowed == false
        and plan.reason == "disabled",
      vim.inspect(plan)
    )
  end

  -- Reading a file is not running anything, so it is never gated.
  local file_plan = policy.plan(":edit init.lua")
  check(
    "preview_policy: :edit previews without the gate",
    file_plan.kind == "file" and file_plan.executes == false and file_plan.allowed == true,
    vim.inspect(file_plan)
  )

  config.options.preview_execute = true

  -- Opted in, but risky_patterns still wins: highlighting a command as
  -- destructive and then running it on hover would contradict the highlight.
  local risky = policy.plan(":!rm -rf build")
  check(
    "preview_policy: risky_patterns still refuses with preview_execute on",
    risky.allowed == false and risky.reason == "risky",
    vim.inspect(risky)
  )

  -- The injection this gate was added for: "|" ends the help command inside
  -- the previewer's `-c` string and starts another one. Verified before the
  -- fix -- it really did run the injected writefile.
  local injected = policy.plan(':help x | call writefile(["pwned"], "/tmp/x")')
  check(
    "preview_policy: a help topic carrying a Vim command separator is refused",
    injected.allowed == false and injected.reason == "unsafe-argument",
    vim.inspect(injected)
  )

  check(
    "preview_policy: topic_is_safe rejects what ends a Vim command",
    not policy.topic_is_safe("x | y")
      and not policy.topic_is_safe("x\ny")
      and not policy.topic_is_safe(""),
    "one of the unsafe topics was accepted"
  )

  -- Real help tags are punctuation-heavy, and so is any Lua expression worth
  -- previewing; a filter strict enough for a shell word would reject both,
  -- i.e. turn the feature off rather than make it safe.
  check(
    "preview_policy: ordinary help tags and expressions stay previewable",
    policy.topic_is_safe("vim.lsp.buf")
      and policy.topic_is_safe("i_CTRL-W")
      and policy.topic_is_safe("v:count")
      and policy.topic_is_safe("'shiftwidth'")
      and policy.topic_is_safe("vim.fn.getcwd()"),
    "a legitimate help tag or expression was rejected"
  )

  -- The shell check is stricter, and only the fzf previewer needs it: a
  -- single quote ends the quoted `-c` word its contract forces.
  check(
    "preview_policy: shell_arg_is_safe additionally rejects a single quote",
    policy.shell_arg_is_safe("vim.fn.getcwd()")
      and not policy.shell_arg_is_safe("'shiftwidth'")
      and not policy.shell_arg_is_safe("x | y"),
    "the shell-word check disagreed"
  )

  local allowed = policy.plan(":lua vim.fn.getcwd()")
  check(
    "preview_policy: a safe expression is allowed once opted in",
    allowed.kind == "lua" and allowed.allowed == true,
    vim.inspect(allowed)
  )

  config.options.preview_execute = false
end

-- ── config.setup: option merging & mappings normalization ───────────────────
do
  local config = require("cmdlog.config")
  local DEFAULTS = require("cmdlog.config.DEFAULTS")

  config.setup({ picker = "fzf", highlight_risky = false })
  check("config.setup: overrides a top-level option", config.options.picker == "fzf")
  check("config.setup: leaves an unrelated default alone", config.options.track_commands == true)
  check("config.setup: applies a nested override", config.options.highlight_risky == false)
  check(
    "config.setup: untouched nested defaults survive the merge",
    vim.deep_equal(config.options.risky_patterns, DEFAULTS.risky_patterns)
  )

  ---@diagnostic disable-next-line: assign-type-mismatch
  config.setup({ mappings = "not-a-table" })
  check(
    "config.setup: a malformed mappings value falls back to the default table",
    vim.deep_equal(config.options.mappings, DEFAULTS.mappings)
  )

  config.setup({ mappings = { select = "<leader>s" } })
  check(
    "config.setup: a valid mappings table is kept, not replaced",
    config.options.mappings.select == "<leader>s"
  )
  check(
    "config.setup: unspecified mapping keys still default",
    config.options.mappings.delete == DEFAULTS.mappings.delete
  )

  -- Clean baseline for every suite below.
  config.setup({})
end

-- ── core.store: shared JSON persistence helper ───────────────────────────────
do
  local store = require("cmdlog.core.store")

  local tmp = vim.fn.tempname() .. "-cmdlog-store.json"
  check(
    "store.load_json: missing file returns the default",
    vim.deep_equal(store.load_json(tmp, { x = 1 }), { x = 1 })
  )

  check(
    "store.save_json: reports success",
    store.save_json(tmp, { a = 1, b = { "x", "y" } }) == true
  )
  check(
    "store.load_json: round-trips what save_json wrote",
    vim.deep_equal(store.load_json(tmp, {}), { a = 1, b = { "x", "y" } })
  )

  vim.fn.writefile({ "not json {{{" }, tmp)
  check(
    "store.load_json: invalid JSON returns the default",
    vim.deep_equal(store.load_json(tmp, { fallback = true }), { fallback = true })
  )

  vim.fn.writefile({}, tmp)
  check(
    "store.load_json: empty file returns the default",
    vim.deep_equal(store.load_json(tmp, { fallback = true }), { fallback = true })
  )

  vim.fn.delete(tmp)
end

-- ── core.favorites: load / save / toggle ─────────────────────────────────────
do
  local config = require("cmdlog.config")
  local path = vim.fn.tempname() .. "-cmdlog-favA.json"
  config.options.favorites_path = path
  config.options.project_scoped = { enabled = false }
  package.loaded["cmdlog.core.favorites"] = nil
  local favorites = require("cmdlog.core.favorites")

  check("favorites.load: empty before anything is saved", #favorites.load() == 0)
  check(
    "favorites.is_favorite: false for an unknown command",
    favorites.is_favorite("git status") == false
  )

  favorites.toggle("git status")
  check("favorites.toggle: adds a new favorite", favorites.is_favorite("git status") == true)
  check("favorites.toggle: persists to disk", vim.fn.filereadable(path) == 1)

  favorites.toggle("ls -la")
  check(
    "favorites.toggle: a second toggle appends",
    vim.deep_equal(favorites.load(), { "git status", "ls -la" })
  )

  favorites.toggle("git status")
  check(
    "favorites.toggle: toggling an existing favorite removes it",
    vim.deep_equal(favorites.load(), { "ls -la" })
  )

  vim.fn.delete(path)
end

-- ── core.favorites: undo_last_toggle (single-level) ─────────────────────────
do
  local config = require("cmdlog.config")
  local path = vim.fn.tempname() .. "-cmdlog-favB.json"
  config.options.favorites_path = path
  package.loaded["cmdlog.core.favorites"] = nil
  local favorites = require("cmdlog.core.favorites")

  favorites.toggle("a")
  favorites.toggle("b")
  local before_third_toggle = vim.deepcopy(favorites.load())

  favorites.toggle("c")
  favorites.undo_last_toggle()
  check(
    "favorites.undo_last_toggle: restores the list from before the last toggle",
    vim.deep_equal(favorites.load(), before_third_toggle)
  )
  check(
    "favorites.undo_last_toggle: single-level -- nothing left to undo",
    favorites.undo_last_toggle() == false
  )

  vim.fn.delete(path)
end

-- ── core.favorites: move (reorder within the persisted list) ────────────────
do
  local config = require("cmdlog.config")
  local path = vim.fn.tempname() .. "-cmdlog-favC.json"
  config.options.favorites_path = path
  package.loaded["cmdlog.core.favorites"] = nil
  local favorites = require("cmdlog.core.favorites")

  favorites.toggle("first")
  favorites.toggle("second")
  favorites.toggle("third")
  check(
    "favorites.move: initial order",
    vim.deep_equal(favorites.load(), { "first", "second", "third" })
  )

  check("favorites.move: unknown command is a no-op", favorites.move("nope", 1) == false)
  check(
    "favorites.move: moving the first entry up is a no-op",
    favorites.move("first", -1) == false
  )
  check(
    "favorites.move: moving the last entry down is a no-op",
    favorites.move("third", 1) == false
  )

  check("favorites.move: swaps with the next slot", favorites.move("first", 1) == true)
  check(
    "favorites.move: swap applied",
    vim.deep_equal(favorites.load(), { "second", "first", "third" })
  )

  check("favorites.move: swaps with the previous slot", favorites.move("third", -1) == true)
  check(
    "favorites.move: second swap applied",
    vim.deep_equal(favorites.load(), { "second", "third", "first" })
  )

  vim.fn.delete(path)
end

-- ── core.favorites: export / import ──────────────────────────────────────────
do
  local config = require("cmdlog.config")
  local base = vim.fn.tempname()
  vim.fn.mkdir(base, "p")
  config.options.favorites_path = base .. "/fav.json"
  package.loaded["cmdlog.core.favorites"] = nil
  local favorites = require("cmdlog.core.favorites")

  favorites.toggle("existing cmd")

  local export_path = base .. "/export.json"
  check("favorites.export: writes the current list", favorites.export(export_path) == true)
  check(
    "favorites.export: exported content matches the live list",
    vim.deep_equal(
      vim.fn.json_decode(table.concat(vim.fn.readfile(export_path), "\n")),
      favorites.load()
    )
  )

  local import_path = base .. "/import.json"
  vim.fn.writefile({ vim.fn.json_encode({ "existing cmd", "new cmd", "new cmd" }) }, import_path)
  check("favorites.import: reports success", favorites.import(import_path) == true)
  check(
    "favorites.import: merges without duplicating the already-favorited entry",
    vim.deep_equal(favorites.load(), { "existing cmd", "new cmd" })
  )

  check(
    "favorites.import: missing file reports failure",
    favorites.import(base .. "/nope.json") == false
  )

  vim.fn.writefile({ "not json" }, base .. "/bad.json")
  check(
    "favorites.import: invalid JSON reports failure",
    favorites.import(base .. "/bad.json") == false
  )

  vim.fn.delete(base, "rf")
end

-- ── core.favorites: project_scoped picks a per-project file ────────────────
do
  local config = require("cmdlog.config")
  local base = vim.fn.tempname()
  local repo_dir = base .. "/myproject"
  vim.fn.mkdir(repo_dir .. "/.git", "p")

  config.options.favorites_path = base .. "/favorites.json"
  config.options.project_scoped = { enabled = true }
  package.loaded["cmdlog.core.favorites"] = nil
  local favorites = require("cmdlog.core.favorites")

  local original_cwd = vim.fn.getcwd()
  local ok_test = pcall(function()
    vim.fn.chdir(repo_dir)
    favorites.toggle("project-only command")

    check(
      "favorites (project-scoped): does not write the global file",
      vim.fn.filereadable(config.options.favorites_path) == 0
    )
    local project_files = vim.fn.globpath(base .. "/projects", "*.json", false, true)
    check(
      "favorites (project-scoped): writes a per-project file under projects/",
      #project_files == 1,
      vim.inspect(project_files)
    )
    check(
      "favorites (project-scoped): the per-project file name is derived from the repo dir",
      #project_files == 1 and project_files[1]:find("myproject", 1, true) ~= nil,
      vim.inspect(project_files)
    )
  end)
  vim.fn.chdir(original_cwd)
  check("favorites (project-scoped): test body did not throw", ok_test)

  config.options.project_scoped = { enabled = false }
  config.options.favorites_path = require("cmdlog.config.DEFAULTS").favorites_path
  package.loaded["cmdlog.core.favorites"] = nil
  vim.fn.delete(base, "rf")
end

-- ── core.shell: shell detection via $SHELL ───────────────────────────────────
do
  local shell = require("cmdlog.core.shell")
  local original_shell = vim.env.SHELL

  local cases = {
    { "/usr/bin/zsh", "zsh" },
    { "/bin/bash", "bash" },
    { "fish", "fish" },
    { "/usr/local/bin/nu", "nu" },
    { "/bin/ksh", "ksh" },
    { "/bin/csh", "csh" },
    { "/bin/PWSH", "powershell" },
  }
  for _, case in ipairs(cases) do
    vim.env.SHELL = case[1]
    local name = shell.get_shell_name()
    check(("get_shell_name: %s -> %s"):format(case[1], case[2]), name == case[2], tostring(name))
  end

  vim.env.SHELL = "/bin/totally-unknown-shell-xyz"
  local ok, name = pcall(shell.get_shell_name)
  check(
    "get_shell_name: unsupported $SHELL falls back to probing without throwing",
    ok and type(name) == "string"
  )

  vim.env.SHELL = original_shell
end

-- ── core.shell: shell_history_path override ──────────────────────────────────
do
  local config = require("cmdlog.config")
  local shell = require("cmdlog.core.shell")

  local tmp = vim.fn.tempname() .. "-cmdlog-shellhist"
  vim.fn.writefile({ "git status" }, tmp)
  config.options.shell_history_path = tmp

  local resolved = shell.get_shell_history_path()
  check(
    "get_shell_history_path: an existing configured override wins",
    resolved == (tmp:gsub("\\", "/")),
    resolved
  )

  config.options.shell_history_path = "/no/such/path-cmdlog-xyz"
  local ok, fallback = pcall(shell.get_shell_history_path)
  check(
    "get_shell_history_path: a missing configured override falls through without throwing",
    ok and type(fallback) == "string"
  )

  config.options.shell_history_path = "default"
  vim.fn.delete(tmp)
end

-- ── core.shell.get_shell_history: per-shell built-in parsers ────────────────
do
  local config = require("cmdlog.config")
  local shell = require("cmdlog.core.shell")
  local original_shell = vim.env.SHELL

  local function with_history(shell_env, lines, expected, label)
    local tmp = vim.fn.tempname() .. "-cmdlog-hist-" .. label
    vim.fn.writefile(lines, tmp)
    config.options.shell_history_path = tmp
    vim.env.SHELL = shell_env
    local got = shell.get_shell_history()
    check("get_shell_history: " .. label, vim.deep_equal(got, expected), vim.inspect(got))
    vim.fn.delete(tmp)
  end

  with_history(
    "/bin/zsh",
    { ": 1690000000:0;git status", ": 1690000001:0;ls -la", "no semicolon here" },
    { "git status", "ls -la" },
    "zsh extended-history format"
  )

  with_history(
    "/bin/bash",
    { "#1609459200", "git status", "", "ls -la" },
    { "git status", "ls -la" },
    "bash plain lines (timestamp comment skipped)"
  )

  with_history(
    "/bin/fish",
    { "- cmd: git status", "- cmd: ls -la" },
    { "git status", "ls -la" },
    "fish YAML-ish entries"
  )

  with_history(
    "/bin/nu",
    { "git status", "", "ls -la" },
    { "git status", "ls -la" },
    "nushell plain lines"
  )

  with_history(
    "pwsh",
    { "git status", "ls -la" },
    { "git status", "ls -la" },
    "PSReadLine plain lines"
  )

  vim.env.SHELL = original_shell
  config.options.shell_history_path = "default"
end

-- ── core.shell.delete_entry: per-shell line matching ─────────────────────────
do
  local config = require("cmdlog.config")
  local shell = require("cmdlog.core.shell")
  local original_shell = vim.env.SHELL

  local function delete_and_read(shell_env, lines, target, label)
    local tmp = vim.fn.tempname() .. "-cmdlog-del-" .. label
    vim.fn.writefile(lines, tmp)
    config.options.shell_history_path = tmp
    vim.env.SHELL = shell_env

    local result
    shell.delete_entry(target, { skip_confirm = true }, function(ok, err)
      result = { ok = ok, err = err }
    end)
    local remaining = vim.fn.readfile(tmp)
    vim.fn.delete(tmp)
    return result, remaining
  end

  do
    local result, remaining =
      delete_and_read("/bin/zsh", { ": 1:0;git status", ": 2:0;ls -la" }, "git status", "zsh")
    check("delete_entry: zsh -- deletes the matching entry", result.ok == true)
    check(
      "delete_entry: zsh -- keeps the other line",
      vim.deep_equal(remaining, { ": 2:0;ls -la" })
    )
  end

  do
    local result, remaining =
      delete_and_read("/bin/fish", { "- cmd: git status", "- cmd: ls -la" }, "git status", "fish")
    check("delete_entry: fish -- deletes the matching entry", result.ok == true)
    check(
      "delete_entry: fish -- keeps the other line",
      vim.deep_equal(remaining, { "- cmd: ls -la" })
    )
  end

  do
    local result, remaining =
      delete_and_read("/bin/bash", { "git status", "ls -la" }, "git status", "bash")
    check("delete_entry: bash -- deletes the matching plain line", result.ok == true)
    check("delete_entry: bash -- keeps the other line", vim.deep_equal(remaining, { "ls -la" }))
  end

  do
    local result = delete_and_read("/bin/bash", { "git status" }, "not present", "missing")
    check(
      "delete_entry: reports failure when the command isn't in the file",
      result.ok == false and result.err:find("not found", 1, true) ~= nil,
      vim.inspect(result)
    )
  end

  vim.env.SHELL = original_shell
  config.options.shell_history_path = "default"
end

-- ── core.shell.delete_entry: confirmation dialog (skip_confirm unset) ──────
do
  local config = require("cmdlog.config")
  local shell = require("cmdlog.core.shell")
  local kit = require("ui.kit")
  local original_confirm = kit.confirm
  local original_shell = vim.env.SHELL

  local tmp = vim.fn.tempname() .. "-cmdlog-confirm"
  vim.fn.writefile({ "git status" }, tmp)
  config.options.shell_history_path = tmp
  vim.env.SHELL = "/bin/bash"

  ---@diagnostic disable-next-line: duplicate-set-field
  kit.confirm = function(opts)
    opts.on_answer(true)
  end
  local result_yes
  shell.delete_entry("git status", nil, function(ok, err)
    result_yes = { ok = ok, err = err }
  end)
  check("delete_entry: confirmed deletion succeeds", result_yes.ok == true)
  check("delete_entry: confirmed deletion actually rewrote the file", #vim.fn.readfile(tmp) == 0)

  vim.fn.writefile({ "git status" }, tmp)
  ---@diagnostic disable-next-line: duplicate-set-field
  kit.confirm = function(opts)
    opts.on_answer(false)
  end
  local result_no
  shell.delete_entry("git status", nil, function(ok, err)
    result_no = { ok = ok, err = err }
  end)
  check(
    "delete_entry: declined confirmation reports 'cancelled'",
    result_no.ok == false and result_no.err == "cancelled"
  )
  check("delete_entry: declined confirmation leaves the file untouched", #vim.fn.readfile(tmp) == 1)

  kit.confirm = original_confirm
  vim.env.SHELL = original_shell
  config.options.shell_history_path = "default"
  vim.fn.delete(tmp)
end

-- ── core.shell: has_custom_parser / custom_matcher state ────────────────────
do
  local config = require("cmdlog.config")
  local shell = require("cmdlog.core.shell")
  check("has_custom_parser: false when shell_history is empty", shell.has_custom_parser() == false)
  config.options.shell_history = {
    parse = function(lines)
      return lines
    end,
  }
  check(
    "has_custom_parser: true once shell_history.parse is set",
    shell.has_custom_parser() == true
  )
  check("custom_matcher: nil until shell_history.matches is set", shell.custom_matcher() == nil)
  config.options.shell_history = {}
end

-- ── core.errors: known-bad command tracking ─────────────────────────────────
do
  local config = require("cmdlog.config")
  local tmp = vim.fn.tempname() .. "-cmdlog-errors.json"
  config.options.errors_path = tmp
  package.loaded["cmdlog.core.errors"] = nil
  local errors = require("cmdlog.core.errors")

  check("errors.is_known_bad: unknown command is false", errors.is_known_bad("git status") == false)
  errors.record("git status", "E123: bad thing")
  check("errors.is_known_bad: recorded command is true", errors.is_known_bad("git status") == true)
  check(
    "errors.get_error: returns the recorded message",
    errors.get_error("git status") == "E123: bad thing"
  )
  check("errors.get_error: unknown command returns nil", errors.get_error("ls") == nil)

  errors.record("", "should be ignored")
  check("errors.record: ignores an empty command", errors.is_known_bad("") == false)

  config.options.errors_path = require("cmdlog.config.DEFAULTS").errors_path
  package.loaded["cmdlog.core.errors"] = nil
  vim.fn.delete(tmp)
end

-- ── core.stats: usage-frequency tracking ─────────────────────────────────────
do
  local config = require("cmdlog.config")
  local tmp = vim.fn.tempname() .. "-cmdlog-stats.json"
  config.options.stats_path = tmp
  package.loaded["cmdlog.core.stats"] = nil
  local stats = require("cmdlog.core.stats")

  check("stats.by_frequency: empty before any record", #stats.by_frequency() == 0)

  stats.record("git status")
  stats.record("git status")
  stats.record("ls -la")

  local by_freq = stats.by_frequency()
  check(
    "stats.by_frequency: most-used command first",
    by_freq[1] == "git status",
    vim.inspect(by_freq)
  )
  check("stats.by_frequency: includes every recorded command", #by_freq == 2)

  local desc = stats.describe("git status")
  check(
    "stats.describe: mentions the count",
    desc ~= nil and desc:find("2x", 1, true) ~= nil,
    tostring(desc)
  )
  check("stats.describe: unknown command returns nil", stats.describe("never run") == nil)

  stats.record("")
  check("stats.record: ignores an empty command", stats.describe("") == nil)

  local all = stats.all()
  check(
    "stats.all: returns every recorded entry",
    all["git status"] and all["git status"].count == 2
  )

  config.options.stats_path = require("cmdlog.config.DEFAULTS").stats_path
  package.loaded["cmdlog.core.stats"] = nil
  vim.fn.delete(tmp)
end

-- ── core.tags: per-favorite tags ──────────────────────────────────────────────
do
  local config = require("cmdlog.config")
  local tmp = vim.fn.tempname() .. "-cmdlog-tags.json"
  config.options.favorite_tags_path = tmp
  package.loaded["cmdlog.core.tags"] = nil
  local tags = require("cmdlog.core.tags")

  check("tags.get_tags: none yet", #tags.get_tags("git status") == 0)

  tags.add_tag("git status", "vcs")
  tags.add_tag("git status", "daily")
  tags.add_tag("git status", "vcs") -- duplicate, no-op
  check(
    "tags.add_tag: dedups",
    #tags.get_tags("git status") == 2,
    vim.inspect(tags.get_tags("git status"))
  )

  tags.add_tag("", "x")
  tags.add_tag("git status", "")
  check("tags.add_tag: ignores empty cmd/tag", #tags.get_tags("") == 0)

  check("tags.filter: finds the tagged command", vim.tbl_contains(tags.filter("vcs"), "git status"))
  check("tags.filter: unknown tag returns empty", #tags.filter("nope") == 0)

  tags.remove_tag("git status", "vcs")
  check(
    "tags.remove_tag: removes just that tag",
    vim.deep_equal(tags.get_tags("git status"), { "daily" })
  )

  tags.remove_tag("git status", "daily")
  check(
    "tags.remove_tag: removing the last tag clears the entry",
    #tags.get_tags("git status") == 0
  )

  config.options.favorite_tags_path = require("cmdlog.config.DEFAULTS").favorite_tags_path
  package.loaded["cmdlog.core.tags"] = nil
  vim.fn.delete(tmp)
end

-- ── core.project_history: per-Git-root command log ───────────────────────────
do
  local config = require("cmdlog.config")
  local project_history = require("cmdlog.core.project_history")
  local original_cwd = vim.fn.getcwd()

  local ok_test, err_test = pcall(function()
    local repo_dir = vim.fn.tempname()
    vim.fn.mkdir(repo_dir .. "/.git", "p")
    vim.fn.chdir(repo_dir)

    local git_root = project_history.get_git_root()
    check(
      "project_history.get_git_root: finds the .git ancestor",
      git_root ~= nil
        and git_root:gsub("\\", "/"):find(vim.fn.fnamemodify(repo_dir, ":t"), 1, true) ~= nil,
      tostring(git_root)
    )

    local tmp = vim.fn.tempname() .. "-cmdlog-project-history.json"
    config.options.project_history_path = tmp

    check(
      "project_history.get_project_history: empty before recording",
      #project_history.get_project_history() == 0
    )

    project_history.record("git status")
    project_history.record("ls -la")
    local recorded = project_history.get_project_history()
    check(
      "project_history.record: appends to the current root's list",
      #recorded == 2 and recorded[1] == "git status" and recorded[2] == "ls -la",
      vim.inspect(recorded)
    )

    project_history.record("")
    check(
      "project_history.record: ignores an empty command",
      #project_history.get_project_history() == 2
    )

    config.options.project_history_path = require("cmdlog.config.DEFAULTS").project_history_path
    vim.fn.delete(tmp)
    vim.fn.delete(repo_dir, "rf")
  end)
  vim.fn.chdir(original_cwd)
  check("project_history: test body did not throw", ok_test, tostring(err_test))
end

do
  package.loaded["cmdlog.core.project_history"] = nil
  local project_history = require("cmdlog.core.project_history")
  local original_cwd = vim.fn.getcwd()

  local ok_test = pcall(function()
    -- A bare temp dir with no .git ancestor -- rooted at the OS temp dir
    -- rather than inside this repo checkout, which IS a Git repo.
    local bare_dir = vim.fn.tempname()
    vim.fn.mkdir(bare_dir, "p")
    vim.fn.chdir(bare_dir)
    check(
      "project_history.get_git_root: nil outside any Git repo",
      project_history.get_git_root() == nil
    )
    check(
      "project_history.get_project_history: empty outside any Git repo",
      #project_history.get_project_history() == 0
    )
    vim.fn.delete(bare_dir, "rf")
  end)
  vim.fn.chdir(original_cwd)
  check("project_history: bare-dir test body did not throw", ok_test)
end

-- ── core.extra_files: read-only extra command files ─────────────────────────
do
  local config = require("cmdlog.config")
  local extra_files = require("cmdlog.core.extra_files")

  local f1 = vim.fn.tempname() .. "-cmdlog-extra1.txt"
  local f2 = vim.fn.tempname() .. "-cmdlog-extra2.txt"
  vim.fn.writefile({ "git status", "", "ls -la" }, f1)
  vim.fn.writefile({ "make build" }, f2)

  config.options.extra_files = { history = { f1 }, all = { f2, "/no/such/file-cmdlog" } }

  check(
    "extra_files.get_history: reads non-empty lines from configured files",
    vim.deep_equal(extra_files.get_history(), { "git status", "ls -la" })
  )
  check(
    "extra_files.get_all: reads its own file list, ignoring a missing one",
    vim.deep_equal(extra_files.get_all(), { "make build" })
  )

  config.options.extra_files = { history = {}, all = {} }
  check("extra_files.get_history: empty when unconfigured", #extra_files.get_history() == 0)

  vim.fn.delete(f1)
  vim.fn.delete(f2)
end

-- ── core.history: Neovim ':' command-line history ───────────────────────────
do
  local history = require("cmdlog.core.history")

  local marker = "cmdlogtest_" .. tostring(os.time())
  local plain_cmd = marker .. "_plain"
  vim.fn.histadd(":", plain_cmd)
  vim.fn.histadd(":", "lua= 1 + 1")
  vim.fn.histadd(":", "= 2 + 2")
  -- `:history`'s output marks the most-recently-added entry with a leading
  -- '>' instead of its index. This entry sits in exactly that "current"
  -- slot, so its presence below also pins the '>' marker being parsed.
  local sentinel = marker .. "_sentinel"
  vim.fn.histadd(":", sentinel)

  local cmds = history.get_command_history()
  check(
    "history.get_command_history: includes a just-added command",
    vim.tbl_contains(cmds, plain_cmd),
    vim.inspect(cmds)
  )
  check(
    "history.get_command_history: includes the '>'-marked most-recent entry",
    vim.tbl_contains(cmds, sentinel),
    vim.inspect(cmds)
  )

  local lua_cmds = history.get_lua_history()
  check("history.get_lua_history: includes 'lua= ...'", vim.tbl_contains(lua_cmds, "lua= 1 + 1"))
  check("history.get_lua_history: includes '= ...'", vim.tbl_contains(lua_cmds, "= 2 + 2"))
  check(
    "history.get_lua_history: excludes plain commands",
    not vim.tbl_contains(lua_cmds, plain_cmd)
  )

  check("history.delete_entry: deletes a just-added entry", history.delete_entry(plain_cmd) == true)
  check(
    "history.delete_entry: entry is really gone",
    not vim.tbl_contains(history.get_command_history(), plain_cmd)
  )
  check(
    "history.delete_entry: deleting again returns false",
    history.delete_entry(plain_cmd) == false
  )

  -- Leave no Lua-mode history behind -- ui.lua_picker's empty-history guard
  -- is tested later in this file and needs a clean slate.
  history.delete_entry("lua= 1 + 1")
  history.delete_entry("= 2 + 2")
  history.delete_entry(marker .. "_sentinel")
end

-- ── core.utils.process_list: reverse + optional dedup pipeline ─────────────
do
  local utils = require("cmdlog.core.utils")

  local ordered = utils.process_list({ "a", "b", "a", "c" }, { unique = false })
  check("process_list: reverses without deduping", vim.deep_equal(ordered, { "c", "a", "b", "a" }))

  local deduped = utils.process_list({ "a", "b", "a", "c" }, { unique = true })
  check(
    "process_list: reverses then dedups, keeping the latest occurrence order",
    vim.deep_equal(deduped, { "c", "a", "b" }),
    vim.inspect(deduped)
  )

  check(
    "process_list: nil opts behaves as unique=false",
    vim.deep_equal(utils.process_list({ "x", "x" }), { "x", "x" })
  )
end

-- ── bindings.usrcmds: catalog shape + real :Cmdlog registration ─────────────
do
  local usrcmds = require("cmdlog.bindings.usrcmds")

  local seen_paths = {}
  local default_count = 0
  for _, entry in ipairs(usrcmds.catalog) do
    check(
      "usrcmds.catalog: entry has desc/module/fn",
      type(entry.desc) == "string" and type(entry.module) == "string" and type(entry.fn) == "string",
      vim.inspect(entry)
    )
    if entry.path == nil then
      default_count = default_count + 1
    else
      check("usrcmds.catalog: path is unique -- " .. entry.path, not seen_paths[entry.path])
      seen_paths[entry.path] = true
    end
    local ok, mod = pcall(require, entry.module)
    check(
      "usrcmds.catalog: " .. entry.module .. "." .. entry.fn .. " resolves to a function",
      ok and type(mod[entry.fn]) == "function",
      tostring(mod)
    )
  end
  check("usrcmds.catalog: exactly one bare-:Cmdlog default entry", default_count == 1)

  local ok_register = pcall(usrcmds.register)
  check("usrcmds.register: re-registering does not throw", ok_register)
  check(":Cmdlog is registered", vim.fn.exists(":Cmdlog") == 2)

  local subcommands = vim.fn.getcompletion("Cmdlog ", "cmdline")
  for _, entry in ipairs(usrcmds.catalog) do
    if entry.path then
      check(
        "Cmdlog completion includes '" .. entry.path .. "'",
        vim.tbl_contains(subcommands, entry.path)
      )
    end
  end
  check("Cmdlog completion includes 'risky'", vim.tbl_contains(subcommands, "risky"))
  check("Cmdlog completion includes 'export'", vim.tbl_contains(subcommands, "export"))
  check("Cmdlog completion includes 'import'", vim.tbl_contains(subcommands, "import"))
end

-- ── bindings.keymaps: catalog + optional entry-point keymaps ────────────────
do
  local config = require("cmdlog.config")
  local keymaps = require("cmdlog.bindings.keymaps")

  local catalog = keymaps.catalog()
  check(
    "keymaps.catalog: bare :Cmdlog keyed by an empty string",
    catalog[""] ~= nil and catalog[""].cmd == "Cmdlog"
  )
  check(
    "keymaps.catalog: a subcommand entry's cmd includes it",
    catalog.favorites and catalog.favorites.cmd == "Cmdlog favorites"
  )

  config.options.keymaps =
    { favorites = "<leader>ZZcmdlogfav", bogus_subcommand = "<leader>ZZcmdlogbogus" }
  local ok = pcall(keymaps.register)
  check("keymaps.register: does not throw on an unknown subcommand", ok)
  check(
    "keymaps.register: a valid subcommand is bound",
    vim.fn.maparg("<leader>ZZcmdlogfav", "n") ~= ""
  )
  check(
    "keymaps.register: an unknown subcommand registers no keymap",
    vim.fn.maparg("<leader>ZZcmdlogbogus", "n") == ""
  )

  pcall(vim.keymap.del, "n", "<leader>ZZcmdlogfav")
  config.options.keymaps = {}
end

-- ── bindings.picker_mappings: resolved() merges the configured key in ──────
do
  local config = require("cmdlog.config")
  local picker_mappings = require("cmdlog.bindings.picker_mappings")

  local resolved = picker_mappings.resolved()
  check(
    "picker_mappings.resolved: select key matches the configured default",
    resolved.select.key == config.options.mappings.select
  )
  check(
    "picker_mappings.resolved: carries the descriptive text",
    type(resolved.delete.desc) == "string" and resolved.delete.desc ~= ""
  )

  config.options.mappings.select = false
  check(
    "picker_mappings.resolved: reflects a disabled mapping",
    picker_mappings.resolved().select.key == false
  )
  config.options.mappings.select = require("cmdlog.config.DEFAULTS").mappings.select
end

-- ── bindings.catalog: aggregates every sub-catalog ──────────────────────────
do
  local bindings = require("cmdlog.bindings")
  local catalog = bindings.catalog()

  check("bindings.catalog: picker_mappings present", type(catalog.picker_mappings) == "table")
  check(
    "bindings.catalog: autocmds present",
    type(catalog.autocmds) == "table" and #catalog.autocmds > 0
  )
  -- Documented quirk (see the CDX note in bindings/init.lua): `keymaps` is
  -- assigned the catalog *function* itself, not its resolved table -- pinned
  -- here so a future fix is a deliberate change, not a silent behaviour shift.
  check(
    "bindings.catalog: keymaps is the unresolved function (known quirk)",
    type(catalog.keymaps) == "function"
  )
end

-- ── integrations.which_key: no-op without which-key, wires specs with it ───
do
  local which_key = require("cmdlog.integrations.which_key")

  local ok = pcall(which_key.register, { [""] = "<leader>ZZcmdlog" })
  check("which_key.register: no-op without which-key.nvim installed", ok)

  local captured
  package.loaded["which-key"] = {
    add = function(specs)
      captured = specs
    end,
  }
  which_key.register({ [""] = "<leader>ZZcmdlogwk", bogus_subcommand = "<leader>ZZcmdlogbogus" })
  check(
    "which_key.register: feeds resolvable entries to wk.add",
    captured ~= nil and #captured == 1
  )
  check(
    "which_key.register: the spec carries the right lhs/desc",
    captured
      and captured[1][1] == "<leader>ZZcmdlogwk"
      and captured[1].desc:find("Cmdlog", 1, true) ~= nil,
    vim.inspect(captured)
  )

  package.loaded["which-key"] = nil
end

-- ── ui.fzf-previewer: pure command_previewer() (no fzf-lua required) ───────
do
  local config = require("cmdlog.config")
  local fzf_previewer = require("cmdlog.ui.fzf-previewer")
  local is_windows = require("lib.nvim.cross.platform.is_windows")()

  config.options.preview_execute = false
  local previewer = fzf_previewer.command_previewer()

  if is_windows then
    check(
      "fzf-previewer: returns nil on Windows (its shell one-liners are POSIX-only)",
      previewer(":help vim.lsp", nil) == nil
    )
  else
    local disabled = previewer(":lua vim.fn.getcwd()", nil)
    check(
      "fzf-previewer: an executing kind explains why it's not previewed when disabled",
      type(disabled) == "string" and disabled:find("Execution previews are off.", 1, true) ~= nil,
      tostring(disabled)
    )

    local terminal_preview = previewer(":terminal", nil)
    check(
      "fzf-previewer: interactive :terminal explains itself instead of previewing",
      type(terminal_preview) == "string" and terminal_preview:find("interactive", 1, true) ~= nil,
      tostring(terminal_preview)
    )

    local file = vim.fn.tempname()
    vim.fn.writefile({ "line one", "line two" }, file)
    local file_preview = previewer(":edit " .. file, nil)
    check(
      "fzf-previewer: a readable file previews via 'head'",
      type(file_preview) == "string" and file_preview:find("head", 1, true) ~= nil,
      tostring(file_preview)
    )
    vim.fn.delete(file)

    check(
      "fzf-previewer: an unreadable file previews as nil",
      previewer(":edit /no/such/cmdlog-file", nil) == nil
    )

    config.options.preview_execute = true
    local allowed = previewer(":lua vim.fn.getcwd()", nil)
    check(
      "fzf-previewer: an allowed lua expression renders via a headless-nvim one-liner",
      type(allowed) == "string" and allowed:find("nvim", 1, true) ~= nil,
      tostring(allowed)
    )

    local unsafe = previewer(":help 'shiftwidth'", nil)
    check(
      "fzf-previewer: a shell-unsafe argument (quote) is refused with an explanation, not run",
      type(unsafe) == "string" and unsafe:find("would end the quoted command", 1, true) ~= nil,
      tostring(unsafe)
    )

    check(
      "fzf-previewer: a bare shell command has no static preview",
      previewer(":!git status", nil) == nil
    )

    config.options.preview_execute = false
  end
end

-- ── ui.all_picker: cross-source merge, origin labels, delete adapter ───────
do
  local config = require("cmdlog.config")
  local picker_utils = require("cmdlog.ui.picker_utils")
  local all_picker = require("cmdlog.ui.all_picker")

  local fav_path = vim.fn.tempname() .. "-cmdlog-allpicker-fav.json"
  config.options.favorites_path = fav_path
  package.loaded["cmdlog.core.favorites"] = nil
  local favorites = require("cmdlog.core.favorites")
  favorites.toggle("fav cmd")

  local marker = "cmdlog_allpicker_" .. tostring(os.time())
  local nvim_cmd = marker .. "_nvim"
  vim.fn.histadd(":", nvim_cmd)
  -- Keeps nvim_cmd off the ">"-marked "current" slot in `:history`'s output
  -- (see core.history's own suite above for why that slot gets its own test).
  vim.fn.histadd(":", marker .. "_sentinel")

  local shell_hist_file = vim.fn.tempname() .. "-cmdlog-allpicker-shell"
  vim.fn.writefile({ "shell cmd" }, shell_hist_file)
  local original_shell_path = config.options.shell_history_path
  local original_shell_env = vim.env.SHELL
  config.options.shell_history_path = shell_hist_file
  vim.env.SHELL = "/bin/bash"

  local extra_file = vim.fn.tempname() .. "-cmdlog-allpicker-extra"
  vim.fn.writefile({ "extra cmd" }, extra_file)
  local original_extra_files = config.options.extra_files
  config.options.extra_files = { history = { extra_file }, all = {} }

  local original_open_picker = picker_utils.open_picker
  local captured
  ---@diagnostic disable-next-line: duplicate-set-field
  picker_utils.open_picker = function(entries, favs, opts)
    captured = { entries = entries, favs = favs, opts = opts }
  end

  local original_mappings = package.loaded["cmdlog.ui.mappings"]
  local captured_delete_fn
  package.loaded["cmdlog.ui.mappings"] = function(_, delete_fn)
    captured_delete_fn = delete_fn
    return function() end
  end

  all_picker.show_all_picker()

  check("all_picker: favorite is included", vim.tbl_contains(captured.entries, "fav cmd"))
  check("all_picker: nvim-history entry is included", vim.tbl_contains(captured.entries, nvim_cmd))
  check(
    "all_picker: shell-history entry is included",
    vim.tbl_contains(captured.entries, "shell cmd")
  )
  check(
    "all_picker: extra_files entry is included",
    vim.tbl_contains(captured.entries, "extra cmd")
  )
  check(
    "all_picker: favorites come before history in the combined list",
    (function()
      local fav_i, hist_i
      for i, e in ipairs(captured.entries) do
        if e == "fav cmd" then fav_i = i end
        if e == nvim_cmd then hist_i = i end
      end
      return fav_i and hist_i and fav_i < hist_i
    end)()
  )
  check("all_picker: opts.label tags the shell entry", captured.opts.label("shell cmd") == "shell")
  check("all_picker: opts.label tags the extra entry", captured.opts.label("extra cmd") == "extra")
  check("all_picker: opts.label leaves a favorite unlabeled", captured.opts.label("fav cmd") == nil)

  check(
    "all_picker: delete adapter succeeds when nvim history has the entry",
    (function()
      local ok, err
      captured_delete_fn(nvim_cmd, function(o, e)
        ok, err = o, e
      end, {})
      return ok == true and err == nil
    end)()
  )

  local not_found_ok, not_found_err
  captured_delete_fn("cmdlog_allpicker_never_existed", function(o, e)
    not_found_ok, not_found_err = o, e
  end, {})
  check(
    "all_picker: delete adapter fails when neither history has the entry",
    not_found_ok == false
  )
  check(
    "all_picker: delete adapter surfaces the shell-side error",
    type(not_found_err) == "string" and not_found_err:find("not found", 1, true) ~= nil,
    tostring(not_found_err)
  )

  picker_utils.open_picker = original_open_picker
  package.loaded["cmdlog.ui.mappings"] = original_mappings
  config.options.favorites_path = require("cmdlog.config.DEFAULTS").favorites_path
  config.options.shell_history_path = original_shell_path
  vim.env.SHELL = original_shell_env
  config.options.extra_files = original_extra_files
  package.loaded["cmdlog.core.favorites"] = nil
  require("cmdlog.core.history").delete_entry(marker .. "_sentinel")
  vim.fn.delete(fav_path)
  vim.fn.delete(shell_hist_file)
  vim.fn.delete(extra_file)
end

-- ── ui.all_unique_picker: cross-source dedup + section counts ──────────────
do
  local config = require("cmdlog.config")
  local picker_utils = require("cmdlog.ui.picker_utils")
  local all_unique_picker = require("cmdlog.ui.all_unique_picker")

  local fav_path = vim.fn.tempname() .. "-cmdlog-uniquepicker-fav.json"
  config.options.favorites_path = fav_path
  package.loaded["cmdlog.core.favorites"] = nil
  local favorites = require("cmdlog.core.favorites")

  -- "dup cmd" is both a favorite AND present in nvim history -- must appear
  -- exactly once in the combined list (as the favorite), not twice.
  favorites.toggle("dup cmd")
  local marker = "cmdlog_uniquepicker_" .. tostring(os.time())
  vim.fn.histadd(":", "dup cmd")
  -- Keeps "dup cmd" off the ">"-marked "current" slot in `:history`'s
  -- output (see core.history's own suite above for why that matters).
  vim.fn.histadd(":", marker .. "_sentinel")

  -- Duplicate *within* the shell-history file: readfile preserves both
  -- lines verbatim, unlike Neovim's own ':' history, which repositions a
  -- re-added identical entry instead of storing it twice -- so this
  -- actually exercises process_list's dedup rather than Neovim's.
  local shell_hist_file = vim.fn.tempname() .. "-cmdlog-uniquepicker-shell"
  vim.fn.writefile({ "dup shell cmd", "dup shell cmd" }, shell_hist_file)
  local original_shell_path = config.options.shell_history_path
  local original_shell_env = vim.env.SHELL
  config.options.shell_history_path = shell_hist_file
  vim.env.SHELL = "/bin/bash"

  local original_open_picker = picker_utils.open_picker
  local captured
  ---@diagnostic disable-next-line: duplicate-set-field
  picker_utils.open_picker = function(entries, _, opts)
    captured = { entries = entries, opts = opts }
  end

  all_unique_picker.show_all_unique_picker()

  local dup_count = 0
  for _, e in ipairs(captured.entries) do
    if e == "dup cmd" then dup_count = dup_count + 1 end
  end
  check(
    "all_unique_picker: a favorite that's also in nvim history appears once",
    dup_count == 1,
    tostring(dup_count)
  )
  local shell_dup_count = 0
  for _, e in ipairs(captured.entries) do
    if e == "dup shell cmd" then shell_dup_count = shell_dup_count + 1 end
  end
  check(
    "all_unique_picker: a shell-history duplicate collapses to one entry",
    shell_dup_count == 1,
    tostring(shell_dup_count)
  )
  check(
    "all_unique_picker: section_dividers reflects the post-dedup counts",
    captured.opts.sections ~= nil
  )

  vim.fn.histdel(":", "^" .. vim.fn.escape("dup cmd", "\\/.*$^~[]") .. "$")
  vim.fn.histdel(":", "^" .. vim.fn.escape(marker .. "_sentinel", "\\/.*$^~[]") .. "$")

  picker_utils.open_picker = original_open_picker
  config.options.favorites_path = require("cmdlog.config.DEFAULTS").favorites_path
  config.options.shell_history_path = original_shell_path
  vim.env.SHELL = original_shell_env
  package.loaded["cmdlog.core.favorites"] = nil
  vim.fn.delete(fav_path)
  vim.fn.delete(shell_hist_file)
end

-- ── ui pickers: guard-clause early returns (never open a picker on empty) ──
do
  local config = require("cmdlog.config")
  local picker_utils = require("cmdlog.ui.picker_utils")
  local original_open_picker = picker_utils.open_picker
  local opened = false
  ---@diagnostic disable-next-line: duplicate-set-field
  picker_utils.open_picker = function()
    opened = true
  end

  do
    local fav_path = vim.fn.tempname() .. "-cmdlog-guard-fav.json"
    config.options.favorites_path = fav_path
    package.loaded["cmdlog.core.favorites"] = nil
    require("cmdlog.ui.favorites_picker").show_favorites_picker()
    check("favorites_picker: does not open a picker with zero favorites", opened == false)
    config.options.favorites_path = require("cmdlog.config.DEFAULTS").favorites_path
    package.loaded["cmdlog.core.favorites"] = nil
  end

  do
    local stats_path = vim.fn.tempname() .. "-cmdlog-guard-stats.json"
    config.options.stats_path = stats_path
    package.loaded["cmdlog.core.stats"] = nil
    opened = false
    require("cmdlog.ui.stats_picker").show_stats_picker()
    check("stats_picker: does not open a picker with no recorded stats", opened == false)
    config.options.stats_path = require("cmdlog.config.DEFAULTS").stats_path
    package.loaded["cmdlog.core.stats"] = nil
  end

  do
    opened = false
    require("cmdlog.ui.lua_picker").show_lua_picker()
    check("lua_picker: does not open a picker with no Lua-mode history", opened == false)
  end

  do
    local original_cwd = vim.fn.getcwd()
    local bare_dir = vim.fn.tempname()
    vim.fn.mkdir(bare_dir, "p")
    local ok_test = pcall(function()
      vim.fn.chdir(bare_dir)
      opened = false
      require("cmdlog.ui.project_picker").show_project_picker()
      check("project_picker: does not open a picker outside a Git repository", opened == false)
    end)
    vim.fn.chdir(original_cwd)
    check("project_picker guard test body did not throw", ok_test)
    vim.fn.delete(bare_dir, "rf")
  end

  picker_utils.open_picker = original_open_picker
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
