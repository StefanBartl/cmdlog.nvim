---@module 'cmdlog.ui.telescope.notes_picker'
--- Telescope picker with editable notes window instead of previewer.

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local picker_utils = require("cmdlog.ui.picker_utils")
local notes = require("cmdlog.core.notes")
local config = require("cmdlog.config")
local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim.notes_picker]")

local api = vim.api

local M = {}

---@return number|nil
local function open_notes_window()
  if not config.options.notes.enabled then
    return nil
  end

  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()

  vim.api.nvim_win_set_width(win, config.options.notes.width or 60)
  vim.api.nvim_set_option_value("number", false, { win = win })
  vim.api.nvim_set_option_value("relativenumber", false, { win = win })
  vim.api.nvim_set_option_value("wrap", true, { win = win })

  return win
end

---@param prompt_bufnr integer
---@return string|nil
---@diagnostic disable-next-line: unused-local
local function get_selected_command(prompt_bufnr)
	local entry = action_state.get_selected_entry()
	if not entry then
		return nil
	end
	return entry.value or entry[1]
end

---@param picker any
---@param prompt_bufnr integer
---@param history string[]
---@diagnostic disable-next-line: unused-local
local function attach_notes(picker, prompt_bufnr, history)
	if not config.options.notes.enabled then
		return
	end

	local picker_win = picker.prompt_win
	api.nvim_set_current_win(picker_win)

	local initial = get_selected_command(prompt_bufnr)
	if not initial then
		return
	end

	local notes_buf = notes.open(initial)
	if not notes_buf then
		notify.error("notes_buf is nil")
		return
	end
	local notes_win = open_notes_window()
   if not notes_win then
      notify.error("notes win is nil in notes picker")
        return
   end

	picker.notes_win = notes_win
	picker.notes_buf = notes_buf

	actions.select_default:replace(function()
		actions.close(prompt_bufnr)
	end)

	picker:register_completion_callback(function()
		local cmd = get_selected_command(prompt_bufnr)
		if not cmd then
			return
		end

		local new_buf = notes.open(cmd)
		if not new_buf then
			notify.error("new_buf is nil")
			return
		end
		if api.nvim_buf_is_valid(new_buf) and api.nvim_win_is_valid(notes_win) then
			api.nvim_win_set_buf(notes_win, new_buf)
			picker.notes_buf = new_buf
		end
	end)
end

---@param history string[]
function M.open(history)
	if not config.options.notes.enabled then
		return
	end

	local caller_win = vim.api.nvim_get_current_win()

	-- Open notes window on the right
	vim.cmd("vsplit")
	local notes_win = vim.api.nvim_get_current_win()

	vim.api.nvim_set_option_value("number", false, { win = notes_win })
	vim.api.nvim_set_option_value("relativenumber", false, { win = notes_win })
	vim.api.nvim_set_option_value("wrap", true, { win = notes_win })

	-- Back to caller for Telescope
	vim.api.nvim_set_current_win(caller_win)

	pickers
		.new({}, {
			prompt_title = "Command History",

			finder = finders.new_table({
				results = history,
			}),

			sorter = conf.generic_sorter({}),
			previewer = false,

			attach_mappings = function(prompt_bufnr, _)
				local notes_win2 = open_notes_window()
                if not notes_win2  then
                    notify.error("notes win 2 is nil in notes picker")
                    return
                end

				-- Initial fill
				if notes_win2 then
					local cmd = picker_utils.get_selected_value(prompt_bufnr)
					if cmd then
						local buf = notes.open(cmd)
                        if not buf then
                            notify.error("buf is nil in notes picker")
                            return
                        end
						if vim.api.nvim_win_is_valid(notes_win2) then
							vim.api.nvim_win_set_buf(notes_win2, buf)
						end
					end
				end

				-- React on selection change
				actions.on_selection_change(function()
					if not notes_win or not vim.api.nvim_win_is_valid(notes_win2) then
						return
					end

					local cmd = picker_utils.get_selected_value(prompt_bufnr)
					if not cmd then
						return
					end

					local buf = notes.open(cmd)
                    if not buf then
                        notify.error("buf is nil in notes picker")
                        return
                    end
					vim.api.nvim_win_set_buf(notes_win2, buf)
				end)

				-- Default <CR>: close picker, keep notes (configurable)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)

					if notes_win and vim.api.nvim_win_is_valid(notes_win2) and not config.options.notes.persist then
						vim.api.nvim_win_close(notes_win2, true)
					end
				end)

				return true
			end,
		})
		:find()
end

return M
