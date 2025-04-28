local previewers = require("telescope.previewers")
local Job = require("plenary.job")
local vim = vim

local M = {}

--- Returns a Telescope buffer previewer that shows file contents if the command targets a readable file.
--- If the command matches patterns like ":edit filename" or ":vsp filename", the file contents are previewed.
--- If the command is a `:help`, `:!<shell>`, `:term`, or `:lua`, show the appropriate preview.
--- @return table
function M.command_previewer()
  return previewers.new_buffer_previewer {
    define_preview = function(self, entry, _)
      local cmd = entry.value or ""

      -- TODO: Preview for ':help <topic>'
      -- TODO: Preview for ':term', ':make', ':lua' commands (context-dependent preview)

      -- Preview for ':!<shell>' - Simulating shell command output
      local shell_cmd = cmd:match("^%s*:?%s*!%s*(.*)$")
      if shell_cmd then
        local job_opts = {
          command = shell_cmd,
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
        }
        Job:new(job_opts):start()
        return
      end


      -- Preview for ':edit <file>', ':vsp <file>', or ':vs <file>'
      local file = cmd:match("^%s*:?%s*e%d?dit%s+(%S+)$")
                or cmd:match("^%s*:?%s*vsp%s+(%S+)$")
                or cmd:match("^%s*:?%s*vs%s+(%S+)$")
      if file and vim.fn.filereadable(file) == 1 then
        local job_opts = {
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
        }
        Job:new(job_opts):start()
      else
        -- No match for file-related command
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {
          "No preview available",
          "",
          "This command does not match any preview pattern."
        })
      end
    end,
  }
end

return M
