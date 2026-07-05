---@module 'cmdlog.ui.picker_utils'
--- Picker abstraction with optional notes integration.

local config = require("cmdlog.config")
local notes = require("cmdlog.core.notes")
local risky = require("cmdlog.core.risky")

local M = {}

---@param prompt_bufnr number
---@return string|nil
---@diagnostic disable-next-line: unused-local
local function get_selected_value(prompt_bufnr)
  local state = require("telescope.actions.state")
  local entry = state.get_selected_entry()
  return entry and entry.value or nil
end

---@return number|nil
local function open_notes_window()
  if not config.options.notes.enabled then
    return nil
  end

  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_width(win, config.options.notes.width)
  vim.api.nvim_set_option_value("number", false, { win = win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = win })
  vim.api.nvim_set_option_value("wrap", true, { win = win })

  return win
end

---@param entries string[]
---@param favs string[]
---@param opts table
function M.open_picker(entries, favs, opts)
  opts = opts or {}

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = opts.prompt_title or ":commands",
    finder = finders.new_table({
      results = entries,
      entry_maker = function(entry)
        return {
          value = entry,
          ordinal = entry,
          display = function()
            if risky.is_risky(entry) then
              return entry, { { { 0, #entry }, "CmdlogRiskyCommand" } }
            end
            return entry
          end,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    previewer = false,

    attach_mappings = function(prompt_bufnr, map)
      local notes_win = open_notes_window()

      local function sync_notes()
        if not notes_win or not vim.api.nvim_win_is_valid(notes_win) then
          return
        end

        local entry = action_state.get_selected_entry()
        if not entry then return end

        local buf = notes.open(entry.value)
        if buf and vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_win_set_buf(notes_win, buf)
        end
      end

      -- Initial buffer fill
      sync_notes()

      -- Register change on CursorMoved in prompt buffer
      vim.api.nvim_buf_attach(prompt_bufnr, false, {
        on_lines = function()
          vim.schedule(sync_notes)
        end,
        on_detach = function() end,
      })

      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        if notes_win and vim.api.nvim_win_is_valid(notes_win) and not config.options.notes.persist then
          vim.api.nvim_win_close(notes_win, true)
        end
      end)

      -- Let the caller register its own mappings (e.g. select/toggle_favorite/refresh
      -- via cmdlog.ui.mappings, which respects config.options.mappings).
      if opts.attach_mappings then
        return opts.attach_mappings(prompt_bufnr, map)
      end

      return true
    end,
  }):find()
end

return M
