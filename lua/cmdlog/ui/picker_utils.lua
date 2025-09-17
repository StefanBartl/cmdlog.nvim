---@module 'cmdlog.ui.picker_utils'
--- Common picker opener (Telescope / fzf-lua) with consistent favorite markers.

local config = require("cmdlog.config")

local M = {}

function M.mark_win_as_cmdlog(win)
	if win and vim.api.nvim_win_is_valid(win) then
		pcall(vim.api.nvim_win_set_var, win, "cmdlog_picker", 1)
	end
end

---@param s string
---@return string
local function norm_cmd(s)
	s = tostring(s or "")
	s = s:match("^%s*(.-)%s*$") or s
	if s:sub(1, 1) == ":" then
		s = s:sub(2)
	end
	return s
end

---@param favs string[]
---@return table<string, true>
local function fav_set(favs)
	local set = {}
	for i = 1, #favs do
		set[norm_cmd(favs[i])] = true
	end
	return set
end

---@param entries string[]
---@param favs string[]
---@return string[]
local function decorate_for_fzf(entries, favs)
	local set = fav_set(favs)
	local out = {}
	for i = 1, #entries do
		local e = entries[i]
		out[i] = (set[norm_cmd(e)] and "★ " or "   ") .. e
	end
	return out
end

--- Strip our star/space prefix from an fzf printed line.
---@param s string
---@return string
local function unwrap_fzf_line(s)
	s = tostring(s or "")
	s = s:gsub("^%s*[★%*]%s+", "") -- star + space
	s = s:gsub("^%s%s%s", "") -- three spaces
	return s
end

function M.open_picker(entries, favs, opts)
	opts = opts or {}
	entries = entries or {}
	favs = favs or {}

	if config.options.picker == "telescope" then
		local ok_t, _ = pcall(require, "telescope")
		if not ok_t then
			vim.notify("[nvim-cmdlog] Telescope not installed", vim.log.levels.WARN)
			return
		end

		local pickers = require("telescope.pickers")
		local finders = require("telescope.finders")
		local conf = require("telescope.config").values
		local previewer = require("cmdlog.ui.telescope_previewer").command_previewer()

		-- Favoriten-Set für Sternprefix
		local set = (function(favs_)
			local s = {}
			for i = 1, #favs_ do
				s[norm_cmd(favs_[i])] = true
			end
			return s
		end)(favs or {})

		local function entry_maker(e)
			e = tostring(e or "")
			local star = set[norm_cmd(e)] and "★ " or "   "
			return {
				value = e, -- was via <CR> ausgeführt wird
				display = star .. e, -- was in der Liste steht
				ordinal = e, -- Sortierschlüssel
			}
		end

		-- Merke das Aufrufer-Fenster & markiere cmdlog-Picker
		vim.g.__cmdlog_caller_win = vim.api.nvim_get_current_win()
		require("cmdlog.ui.picker_utils").mark_win_as_cmdlog(vim.g.__cmdlog_caller_win)

		pickers
			.new({}, {
				prompt_title = opts.prompt_title or ":commands",
				finder = finders.new_table({ results = entries or {}, entry_maker = entry_maker }),
				sorter = conf.generic_sorter({}),
				previewer = previewer,
				attach_mappings = (function()
					if type(opts.attach_mappings) == "function" then
						return opts.attach_mappings
					end
					-- Fallback: nichts extra mappen, nur anzeigen
					return function()
						return true
					end
				end)(),
			})
			:find()

		return
	elseif config.options.picker == "fzf" or config.options.picker == "fzf-lua" then
		local fzf = require("fzf-lua")
		local previewer = require("cmdlog.ui.fzf_previewer").command_previewer()

		local function start_fzf()
			-- refresh favorites right before opening
			local current_favs = require("cmdlog.core.favorites").load()
			local list = decorate_for_fzf(entries, current_favs)

			fzf.fzf_exec(list, {
				prompt = opts.fzf_prompt or ":commands> ",
				preview = previewer,
				actions = (function()
					if opts.actions then
						return opts.actions
					end
					return {
						["default"] = function(selected)
							if selected and selected[1] then
								local raw = unwrap_fzf_line(selected[1])
								vim.cmd(raw)
							end
						end,
						["tab"] = function(selected)
							if selected and selected[1] then
								local raw = unwrap_fzf_line(selected[1])
								require("cmdlog.core.favorites").toggle(raw)
								vim.schedule(start_fzf)
							end
						end,
						["ctrl-f"] = function(selected)
							if selected and selected[1] then
								local raw = unwrap_fzf_line(selected[1])
								require("cmdlog.core.favorites").toggle(raw)
								vim.schedule(start_fzf)
							end
						end,
					}
				end)(),
				winopts = {
					on_create = function()
						M.mark_win_as_cmdlog(vim.api.nvim_get_current_win())
					end,
				},
			})
		end

		start_fzf()
	else
		vim.notify("[nvim-cmdlog] Unknown picker: " .. tostring(config.options.picker), vim.log.levels.ERROR)
	end
end

return M
