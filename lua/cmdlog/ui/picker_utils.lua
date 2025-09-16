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
  if s:sub(1, 1) == ":" then s = s:sub(2) end
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
  s = s:gsub("^%s%s%s", "")      -- three spaces
  return s
end

function M.open_picker(entries, favs, opts)
  opts = opts or {}
  entries = entries or {}
  favs = favs or {}

  -- NEW: remember the window where the picker was opened from
  vim.g.__cmdlog_caller_win = vim.api.nvim_get_current_win()

  if config.options.picker == "telescope" then
    -- … (unverändert) …
  elseif config.options.picker == "fzf" or config.options.picker == "fzf-lua" then
    local fzf = require("fzf-lua")
    local previewer = require("cmdlog.ui.fzf_previewer").command_previewer()

    local function start_fzf()
      -- refresh favorites right before opening
      local current_favs = require("cmdlog.core.favorites").load()
      local list = decorate_for_fzf(entries, current_favs)

      -- keep the caller win up to date in case user reopens
      vim.g.__cmdlog_caller_win = vim.api.nvim_get_current_win()

      fzf.fzf_exec(list, {
        prompt = opts.fzf_prompt or ":commands> ",
        preview = previewer,
        actions = (function()
          if opts.actions then return opts.actions end
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
local _closing_guard = false

--- Capture :messages without letting any UI steal the preview window focus.
---@param max integer|nil
---@return string
function M.capture_messages_safely(max)
  max = max or 200

  -- current = preview window (because previewer runs in it)
  local preview_win = vim.api.nvim_get_current_win()

  -- prefer the user window that opened the picker
  local caller_win = vim.g.__cmdlog_caller_win
  if not (caller_win and vim.api.nvim_win_is_valid(caller_win)) then
    -- fallback: try to find any *other* normal window
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= preview_win then
        caller_win = w
        break
      end
    end
  end

  -- snapshot windows before
  local before = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do before[w] = true end

  -- mark phase for external UIs (e.g. Noice routes)
  local had_flag = vim.g.__cmdlog_capturing_messages
  vim.g.__cmdlog_capturing_messages = true

  local function do_capture()
    -- 1) quiet execute
    local ok, out = pcall(vim.fn.execute, "silent messages")
    if not ok then out = "" end
    if (out or "") == "" then
      -- 2) :redir fallback
      local script = table.concat({
        "redir => g:__cmdlog_msgs",
        "silent messages",
        "redir END",
        "echo g:__cmdlog_msgs",
        "unlet g:__cmdlog_msgs",
      }, " | ")
      local ok2, res = pcall(vim.api.nvim_exec2, script, { output = true })
      out = (ok2 and res and res.output) or ""
    end
    return tostring(out or "")
  end

  -- run the capture in the *caller* window, not in the preview window
  local out
  if caller_win and vim.api.nvim_win_is_valid(caller_win) then
    local ok, res = pcall(vim.api.nvim_win_call, caller_win, do_capture)
    out = ok and res or ""
  else
    out = do_capture()
  end

  -- cleanup (close any *new* windows and restore focus to preview)
  if not _closing_guard then
    _closing_guard = true
    vim.schedule(function()
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if not before[w] then
          pcall(vim.api.nvim_win_close, w, true)
        end
      end
      if vim.api.nvim_win_is_valid(preview_win) then
        pcall(vim.api.nvim_set_current_win, preview_win)
      end
      vim.g.__cmdlog_capturing_messages = had_flag and true or nil
      _closing_guard = false
    end)
  end

  if out == "" then out = "[no messages]" end

  -- trim to N lines
  local n, buf = 0, {}
  for line in out:gmatch("([^\n]*)\n?") do
    n = n + 1; buf[n] = line
    if n >= max then break end
  end
  return table.concat(buf, "\n")
end
return M
