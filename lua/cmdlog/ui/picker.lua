local composer = require("lib.nvim.usercmd.composer")

local history_picker = require("cmdlog.ui.history_picker")
local unique_picker = require("cmdlog.ui.history_unique_picker")
local favorites_picker = require("cmdlog.ui.favorites_picker")
local all_picker = require("cmdlog.ui.all_picker")
local all_unique_picker = require("cmdlog.ui.all_unique_picker")
local shell_picker = require("cmdlog.ui.shell_picker")
local shell_unique_picker = require("cmdlog.ui.shell_unique_picker")

local M = {}

--- Registers :Cmdlog <subcommand>, built via lib.nvim.usercmd.composer.
--- Bare `:Cmdlog` (no subcommand) keeps its original meaning -- the
--- all-repos, deduplicated picker -- via the verb's `default` handler.
--- Every picker function is unchanged; only the registration site moved.
--- @return nil
function M.register_command()
  composer.verb("Cmdlog", {
    desc = "Command history pickers",
    default = all_unique_picker.show_all_unique_picker,
    routes = {
      { path = { "full" }, desc = "All commands, including duplicates",
        run = all_picker.show_all_picker },
      { path = { "nvim" }, desc = "Neovim command-line history, deduplicated",
        run = unique_picker.show_history_unique_picker },
      { path = { "nvim-full" }, desc = "Neovim command-line history, including duplicates",
        run = history_picker.show_history_picker },
      { path = { "shell" }, desc = "Shell command history, deduplicated",
        run = shell_unique_picker.show_shell_unique_picker },
      { path = { "shell-full" }, desc = "Shell command history, including duplicates",
        run = shell_picker.show_shell_picker },
      { path = { "favorites" }, desc = "Favorited commands",
        run = favorites_picker.show_favorites_picker },
    },
  })
end

return M
