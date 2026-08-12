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
  "cmdlog.core.notes",
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
  "cmdlog.ui.telescope.notes_picker",
}

-- Modules that only load when telescope.nvim is present (lazily required by
-- their callers, never at plugin-setup time -- see cmdlog.ui.picker_utils).
-- When telescope isn't on the runtimepath (e.g. a bare CI lint job), treat
-- that specific failure as a skip rather than a hard failure.
local optional_telescope_modules = {
  ["cmdlog.ui.telescope-previewer"] = true,
  ["cmdlog.ui.telescope.notes_picker"] = true,
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

-- ── :checkhealth cmdlog (smoke only -- asserts it runs without erroring) ────
do
  local ok, err = pcall(function()
    require("cmdlog.health").check()
  end)
  check("cmdlog.health.check() runs without error", ok, err)
end

print(("\n%d passed, %d failed, %d skipped"):format(passed, failed, skipped))
if failed > 0 then os.exit(1) end
