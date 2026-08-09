---@module 'cmdlog.ui.cycle'
--- Lets `mappings.cycle_source` rotate through a fixed set of pickers
--- without leaving the prompt, carrying over whatever text was typed so
--- far. Telescope only: fzf-lua entries double as the value fed back to
--- `actions` (see ui/picker_utils.lua), so this follows the same
--- Telescope-only precedent as risky-command highlighting and labels.

---@type { name: string, show: fun(initial_text: string|nil) }[]
local order = {
  {
    name = "nvim",
    show = function(text)
      require("cmdlog.ui.history_unique_picker").show_history_unique_picker(text)
    end,
  },
  {
    name = "shell",
    show = function(text)
      require("cmdlog.ui.shell_unique_picker").show_shell_unique_picker(text)
    end,
  },
  {
    name = "favorites",
    show = function(text)
      require("cmdlog.ui.favorites_picker").show_favorites_picker(text)
    end,
  },
  {
    name = "project",
    show = function(text)
      require("cmdlog.ui.project_picker").show_project_picker(text)
    end,
  },
}

local M = {}

--- Binds `mappings.cycle_source` (if configured) inside `map`, closing the
--- current picker and reopening the next one in rotation with the current
--- prompt text carried over. No-op if the mapping is disabled/unset.
---@param prompt_bufnr number
---@param map fun(mode: string, lhs: string, fn: function)
---@param current_name string One of `order`'s `name` values
---@return nil
function M.attach(prompt_bufnr, map, current_name)
  local mappings = require("cmdlog.config").options.mappings
  if not mappings.enabled or not mappings.cycle_source then return end

  map("i", mappings.cycle_source, function()
    local action_state = require("telescope.actions.state")
    local actions = require("telescope.actions")
    local text = action_state.get_current_line()

    local idx = 1
    for i, entry in ipairs(order) do
      if entry.name == current_name then
        idx = i
        break
      end
    end
    local next_source = order[(idx % #order) + 1]

    actions.close(prompt_bufnr)
    vim.schedule(function()
      next_source.show(text)
    end)
  end)
end

return M
