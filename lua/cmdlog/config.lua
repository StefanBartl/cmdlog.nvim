local default_config = {
  -- Path to the favorites file, can be overridden via setup()
  favorites_path = vim.fn.stdpath("data") .. "/nvim-cmdlog/favorites.json",
}

local M = {}

--- Store the merged config
M.options = {
  picker = "telescope" -- or fzf
}

--- Setup config by merging user options with defaults
--- @param user_config table|nil
function M.setup(user_config)
  M.options = vim.tbl_deep_extend("force", {}, default_config, user_config or {})
end

return M
