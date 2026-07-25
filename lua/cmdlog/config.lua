local M = {}

-- Default-Konfiguration
local default_config = {
  favorites_path = vim.fn.stdpath("data") .. "/nvim-cmdlog/favorites.json",
  picker = "telescope",           -- or "fzf"
  shell_history_path = "default", -- or a specific file path

  favorite_tags_path = vim.fn.stdpath("data") .. "/nvim-cmdlog/favorite_tags.json",
  project_history_path = vim.fn.stdpath("data") .. "/nvim-cmdlog/project_history.json",
  stats_path = vim.fn.stdpath("data") .. "/nvim-cmdlog/stats.json",
  errors_path = vim.fn.stdpath("data") .. "/nvim-cmdlog/errors.json",

  track_commands = true, -- record every ':' command for project history, stats and error tracking

  -- Optional: map of :Cmdlog subcommand -> lhs, registered as normal-mode
  -- keymaps (with which-key descriptions when which-key.nvim is installed).
  -- Use "" for bare `:Cmdlog`. Empty by default: no keymaps are created.
  keymaps = {},
}

-- Speichert die aktuelle Konfiguration
M.options = vim.deepcopy(default_config)

--- Setup config by merging user options with defaults
--- @param user_config table|nil
function M.setup(user_config)
  M.options = vim.tbl_deep_extend("force", {}, default_config, user_config or {})
end

return M

