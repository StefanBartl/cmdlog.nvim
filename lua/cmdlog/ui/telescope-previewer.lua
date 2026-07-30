local previewers = require("telescope.previewers")
local Job = require("plenary.job")
local vim = vim

local M = {}

--- Whether `word` is a valid Vim command abbreviation of `full`
--- (e.g. "ter" is an abbreviation of "terminal", but "te" is too short).
---@param word string
---@param full string
---@param min_len integer
---@return boolean
local function is_abbrev_of(word, full, min_len)
  return word ~= nil and #word >= min_len and full:sub(1, #word) == word
end

--- Returns a Telescope buffer previewer that shows file contents if the command targets a readable file.
--- If the command matches patterns like ":edit filename" or ":vsp filename", the file contents are previewed.
--- If the command is a `:help`, `:!<shell>`, `:term`, or `:lua`, show the appropriate preview.
--- @return table
function M.command_previewer()
  return previewers.new_buffer_previewer {
    define_preview = function(self, entry, _)
      local cmd = entry.value or ""

      -- Preview for ':lua <expr>' - evaluated in-process, no subprocess needed
      local lua_expr = cmd:match("^%s*:?%s*lua%s+(.*)$")
      if lua_expr then
        local chunk, load_err = load("return " .. lua_expr)
        if not chunk then
          chunk, load_err = load(lua_expr)
        end
        if not chunk then
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Failed to parse Lua expression:", tostring(load_err) })
          return
        end
        local ok, result = pcall(chunk)
        local lines = ok and vim.split(vim.inspect(result), "\n") or { "Error evaluating Lua expression:", tostring(result) }
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        return
      end

      -- First word of the command and everything after it, used to
      -- disambiguate short abbreviations (":h" for help, ":ter" for
      -- terminal) from unrelated commands sharing the same prefix
      -- (":hide", ":terse plugin", ...).
      local head_word, tail = cmd:match("^%s*:?%s*(%a+)%s*(.-)$")
      local bare_head_word = cmd:match("^%s*:?%s*(%a+)%s*$")

      -- Preview for ':help <topic>' - rendered via a headless Neovim instance
      local help_topic = (is_abbrev_of(head_word, "help", 1) and tail ~= "" ) and tail or nil
      if help_topic then
        local job_opts = {
          command = "nvim",
          args = { "--headless", "-u", "NONE", "-c",
            "redir @a | silent! help " .. help_topic .. " | redir END | put a | %print | quit!" },
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

      -- Preview for ':term[inal] [cmd]' - show the output the terminal buffer would run
      if is_abbrev_of(head_word, "terminal", 3) and tail ~= "" then
        Job:new({
          command = vim.o.shell,
          args = { vim.o.shellcmdflag, tail },
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
        return
      elseif is_abbrev_of(bare_head_word, "terminal", 3) then
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, { "Opens an interactive terminal buffer.", "No static preview available." })
        return
      end

      -- Preview for ':!<shell>' - Simulating shell command output
      local shell_cmd = cmd:match("^%s*:?%s*!%s*(.*)$")
      if shell_cmd then
        local preview_bufnr = self.state.bufnr
        local job_opts = {
          command = shell_cmd,
          on_stdout = function(_, line)
            vim.schedule(function()
              if not vim.api.nvim_buf_is_valid(preview_bufnr) then
                return
              end
              vim.api.nvim_buf_set_lines(preview_bufnr, -1, -1, false, { line })
            end)
          end,
          on_stderr = function(_, err)
            if err and err ~= "" then
              vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(preview_bufnr) then
                  return
                end
                vim.api.nvim_buf_set_lines(preview_bufnr, -1, -1, false, { "Error: " .. err })
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
        local preview_bufnr = self.state.bufnr
        local job_opts = {
          command = "head",
          args = { "-n", "50", file },
          on_stdout = function(_, line)
            vim.schedule(function()
              if not vim.api.nvim_buf_is_valid(preview_bufnr) then
                return
              end
              vim.api.nvim_buf_set_lines(preview_bufnr, -1, -1, false, { line })
            end)
          end,
          on_stderr = function(_, err)
            if err and err ~= "" then
              vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(preview_bufnr) then
                  return
                end
                vim.api.nvim_buf_set_lines(preview_bufnr, -1, -1, false, { "Error: " .. err })
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
