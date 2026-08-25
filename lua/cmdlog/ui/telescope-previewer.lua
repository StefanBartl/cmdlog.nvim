---@module 'cmdlog.ui.telescope-previewer'
--- Builds the Telescope buffer previewer for command-history entries.
---
--- What may be previewed how is decided by `cmdlog.ui.preview_policy`, not
--- here: a preview reads, it does not run. Anything that would execute needs
--- `preview_execute = true` and a non-risky entry. See that module for why.

local previewers = require("telescope.previewers")
local job = require("lib.nvim.system.job")
local policy = require("cmdlog.ui.preview_policy")
local vim = vim

local M = {}

---@internal
---Replace the preview buffer's contents, if it is still around. A preview
---buffer outlives neither a fast cursor nor a closed picker, and the async
---branches below can land after either.
---@param bufnr integer
---@param lines string[]
local function render(bufnr, lines)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

---@internal
---Append one line to the preview buffer.
---@param bufnr integer
---@param line string
local function append(bufnr, line)
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { line })
end

---@internal
---Stream a job's output into the preview buffer.
---@param bufnr integer
---@param opts table  job.start options minus the output handlers
local function stream(bufnr, opts)
  opts.on_stdout = function(_, line)
    vim.schedule(function()
      append(bufnr, line)
    end)
  end
  opts.on_stderr = function(_, err)
    if err and err ~= "" then
      vim.schedule(function()
        append(bufnr, "Error: " .. err)
      end)
    end
  end
  job.start(opts)
end

--- Returns the Telescope buffer previewer.
---
--- `:edit <file>` shows the file's first lines. `:help`, `:lua`, `:terminal`
--- and `:!` would each have to run something, so they show the command and
--- why it was not run unless `preview_execute` is enabled.
--- @return table
function M.command_previewer()
  return previewers.new_buffer_previewer({
    define_preview = function(self, entry, _)
      local cmd = entry.value or ""
      local bufnr = self.state.bufnr
      local plan = policy.plan(cmd)

      if not plan.allowed then
        render(bufnr, policy.explain(cmd, plan))
        return
      end

      -- Read, not `head`: the file is right there, and shelling out for the
      -- first fifty lines of it needed a `head` on PATH, which Windows has
      -- no reason to have.
      if plan.kind == "file" then
        if vim.fn.filereadable(plan.arg) ~= 1 then
          render(bufnr, { cmd, "", "File not readable: " .. plan.arg })
          return
        end
        local ok, lines = pcall(vim.fn.readfile, plan.arg, "", 50)
        render(bufnr, ok and lines or { cmd, "", "Could not read: " .. plan.arg })
        return
      end

      render(bufnr, {})

      if plan.kind == "help" then
        stream(bufnr, {
          command = "nvim",
          args = {
            "--headless",
            "-u",
            "NONE",
            "-c",
            "redir @a | silent! help " .. plan.arg .. " | redir END | put a | %print | quit!",
          },
        })
        return
      end

      if plan.kind == "lua" then
        local chunk, load_err = load("return " .. plan.arg)
        if not chunk then
          chunk, load_err = load(plan.arg)
        end
        if not chunk then
          render(bufnr, { "Failed to parse Lua expression:", tostring(load_err) })
          return
        end
        local ok, result = pcall(chunk)
        render(
          bufnr,
          ok and vim.split(vim.inspect(result), "\n")
            or { "Error evaluating Lua expression:", tostring(result) }
        )
        return
      end

      if plan.kind == "terminal" then
        stream(bufnr, { command = vim.o.shell, args = { vim.o.shellcmdflag, plan.arg } })
        return
      end

      if plan.kind == "shell" then
        stream(bufnr, { command = plan.arg })
        return
      end
    end,
  })
end

return M
