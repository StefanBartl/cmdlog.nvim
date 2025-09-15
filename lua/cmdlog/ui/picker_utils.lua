---@module 'cmdlog.ui.picker_utils'
--- Common picker opener (Telescope / fzf-lua) with consistent favorite markers.

local config = require("cmdlog.config")

local M = {}

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

--- Opens a picker (Telescope or fzf-lua) based on configuration.
--- @param entries string[]
--- @param favs string[]
--- @param opts table  Options: prompt_title, fzf_prompt, attach_mappings (tel), actions (fzf)
--- @return nil
function M.open_picker(entries, favs, opts)
  opts = opts or {}
  entries = entries or {}
  favs = favs or {}

  if config.options.picker == "telescope" then
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local set = fav_set(favs)

    pickers.new({}, {
      prompt_title = opts.prompt_title or ":commands",
      finder = finders.new_table {
        results = entries,
        entry_maker = function(entry)
          local mark = set[norm_cmd(entry)] and "★ " or "   "
          return {
            value = entry,
            display = mark .. entry,  -- FIX: '..' not '.'
            ordinal = entry,
          }
        end,
      },
      sorter = conf.generic_sorter({}),
      previewer = require("cmdlog.ui.telescope-previewer").command_previewer(),
      attach_mappings = opts.attach_mappings,
    }):find()

  elseif config.options.picker == "fzf" or config.options.picker == "fzf-lua" then
    local fzf = require("fzf-lua")
    local previewer = require("cmdlog.ui.fzf-previewer").command_previewer()

    local function start_fzf()
      -- Always take the latest favorites just before showing
      local current_favs = require("cmdlog.core.favorites").load()
      local list = decorate_for_fzf(entries, current_favs)

      fzf.fzf_exec(list, {
        prompt = opts.fzf_prompt or ":commands> ",
        preview = previewer, -- FIX: fzf-lua uses 'preview'
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
                vim.schedule(start_fzf) -- fast reopen to reflect star removal/add
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
      })
    end

    start_fzf()

  else
    vim.notify("[nvim-cmdlog] Unknown picker: " .. tostring(config.options.picker), vim.log.levels.ERROR)
  end
end

return M
