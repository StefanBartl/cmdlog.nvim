---@module 'cmdlog.ui.project_picker'
--- Picker showing command history recorded for the current Git project only.

local favorites = require("cmdlog.core.favorites")
local project_history = require("cmdlog.core.project_history")
local process_list = require("cmdlog.core.utils").process_list
local picker_utils = require("cmdlog.ui.picker_utils")
local cycle = require("cmdlog.ui.cycle")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim]")

local M = {}

--- Loads and shows a picker with commands recorded while working inside the
--- current Git project only. Only commands run after tracking was enabled
--- (config.options.track_commands) are recorded; there is no retroactive
--- attribution of pre-existing Neovim history to a project.
--- @param initial_text? string Prompt text to pre-fill, used by `mappings.cycle_source`
--- @return nil
function M.show_project_picker(initial_text)
  if not project_history.get_git_root() then
    notify.info("Not inside a Git repository")
    return
  end

  local favs = favorites.load()
  local raw = project_history.get_project_history()
  local entries = process_list(raw, { unique = true })

  if #entries == 0 then
    notify.info("No project-local history recorded yet")
    return
  end

  picker_utils.open_picker(entries, favs, {
    prompt_title = ":history (current project)",
    fzf_prompt = ":project> ",
    default_text = initial_text,
    attach_mappings = function(prompt_bufnr, map)
      cycle.attach(prompt_bufnr, map, "project")
      return require("cmdlog.ui.mappings")(M.show_project_picker)(prompt_bufnr, map)
    end,
  })
end

return M
