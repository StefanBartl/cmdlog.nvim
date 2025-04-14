local previewers = require("telescope.previewers")
local Job = require("plenary.job")

local M = {}

--- Returns a previewer that shows file contents if the command is e.g. :edit somefile.txt
function M.command_previewer()
  return previewers.new_buffer_previewer {
    define_preview = function(self, entry, _)
      local cmd = entry.value or ""

      -- Try to match simple patterns like ":edit file.txt" or ":vsp file.txt"
      local file = cmd:match("^%s*:?%s*e%d?dit%s+(%S+)$")
                or cmd:match("^%s*:?%s*vsp%s+(%S+)$")
                or cmd:match("^%s*:?%s*vs%s+(%S+)$")

      if file and vim.fn.filereadable(file) == 1 then
        Job:new({
          command = "head",
          args = { "-n", "50", file },
          on_stdout = function(_, line)
            vim.schedule(function()
              vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, false, { line })
            end)
          end,
          on_stderr = function(_, err)
            if err and err ~= "" then
              vim.schedule(function()
                vim.api.nvim_buf_set_lines(self.state.bufnr, -1, -1, false, { "Error: " .. err })
              end)
            end
          end,
        }):start()
      else
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
          "No preview available",
          "",
          "This command does not reference a readable file."
        })
      end
    end,
  }
end

return M
