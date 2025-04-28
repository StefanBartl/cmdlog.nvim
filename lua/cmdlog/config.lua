local M = {}

-- Default-Konfiguration
local default_config = {
  favorites_path = vim.fn.stdpath("data") .. "/nvim-cmdlog/favorites.json",
  picker = "telescope",           -- or "fzf"
  shell_history_path = "default", -- or a specific file path
}

-- Speichert die aktuelle Konfiguration
M.options = vim.deepcopy(default_config)

--- Setup config by merging user options with defaults
--- @param user_config table|nil
function M.setup(user_config)
  M.options = vim.tbl_deep_extend("force", {}, default_config, user_config or {})
end

return M

