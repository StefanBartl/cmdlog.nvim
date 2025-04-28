local config = require("cmdlog.config")

local M = {}

--- Opens a picker (Telescope or fzf-lua) based on configuration.
--- @param entries string[]: List of entries (already combined if needed)
--- @param favs string[]: List of favorite commands
--- @param opts table: Table with options like prompt_title, fzf_prompt, attach_mappings, actions
--- @return nil
function M.open_picker(entries, favs, opts)
  opts = opts or {}

  if config.options.picker == "telescope" then
    require("telescope.pickers").new({}, {
      prompt_title = opts.prompt_title or ":commands",
      finder = require("telescope.finders").new_table {
        results = entries,
        entry_maker = function(entry)
          local is_fav = vim.tbl_contains(favs, entry)
          return {
            value = entry,
            display = (is_fav and "★ " or "   ") .. entry,
            ordinal = entry,
          }
        end,
      },
      sorter = require("telescope.config").values.generic_sorter({}),
      previewer = require("cmdlog.ui.telescope-previewer").command_previewer(),
      attach_mappings = opts.attach_mappings,
    }):find()

  elseif config.options.picker == "fzf" then
    local fzf = require("fzf-lua")
    fzf.fzf_exec(entries, {
      prompt = opts.fzf_prompt or ":commands> ",
      previewer = require("cmdlog.ui.fzf-previewer").command_previewer(),
      actions = opts.actions or {
        ["default"] = function(selected)
          if selected[1] then
            vim.cmd(selected[1])
          end
        end,
      },
    })

  else
    vim.notify("[nvim-cmdlog] Unknown picker: " .. tostring(config.options.picker), vim.log.levels.ERROR)
  end
end

return M
