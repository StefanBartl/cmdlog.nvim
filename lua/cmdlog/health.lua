---@module 'cmdlog.health'
--- :checkhealth cmdlog — verifies dependencies and configuration.

local M = {}

---@param modname string
---@return boolean
local function has_module(modname)
  return (pcall(require, modname))
end

function M.check()
  local health = vim.health or require("health")
  local start = health.start or health.report_start
  local ok = health.ok or health.report_ok
  local warn = health.warn or health.report_warn
  local error_ = health.error or health.report_error

  start("cmdlog.nvim")

  if vim.fn.has("nvim-0.9") == 1 then
    ok("Neovim version >= 0.9")
  else
    warn("Neovim < 0.9 detected — cmdlog.nvim targets 0.9+")
  end

  if has_module("lib.nvim.fs.is_dir") then
    ok("lib.nvim found (required for cross-platform fs/notify helpers)")
  else
    error_("lib.nvim not found — install StefanBartl/lib.nvim")
  end

  local config_ok, config = pcall(require, "cmdlog.config")
  if not config_ok then
    error_("cmdlog.config could not be loaded: " .. tostring(config))
    return
  end

  local picker = config.options.picker
  if picker == "telescope" then
    if has_module("telescope") then
      ok("picker = 'telescope' and telescope.nvim found")
    else
      error_("picker = 'telescope' but telescope.nvim is not installed")
    end
  elseif picker == "fzf" or picker == "fzf-lua" then
    if has_module("fzf-lua") then
      ok("picker = '" .. picker .. "' and fzf-lua found")
    else
      error_("picker = '" .. picker .. "' but fzf-lua is not installed")
    end
  else
    error_("Invalid config.options.picker: '" .. tostring(picker) .. "' (expected 'telescope' or 'fzf')")
  end

  local shell = require("cmdlog.core.shell")
  local shell_name = shell.get_shell_name()
  if shell_name ~= "" then
    ok("Detected shell: " .. shell_name)
    local hist_path = shell.get_shell_history_path()
    if hist_path ~= "" then
      ok("Shell history file found: " .. hist_path)
    else
      warn("Shell '" .. shell_name .. "' detected, but no history file found")
    end
  else
    warn("Could not detect a supported shell (SHELL unset and no known history file found)")
  end

  if config.options.notes.enabled then
    local notes_dir = config.options.notes.dir
    if vim.fn.isdirectory(notes_dir) == 1 then
      ok("Notes directory exists: " .. notes_dir)
    else
      warn("Notes directory does not exist yet (created on first note): " .. notes_dir)
    end
  else
    ok("Notes feature disabled")
  end

  require("lib.nvim.usercmd.composer").checkhealth("Cmdlog")
end

return M
