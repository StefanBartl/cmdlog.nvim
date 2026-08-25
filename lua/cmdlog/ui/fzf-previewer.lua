---@module 'cmdlog.ui.fzf-previewer'
--- Builds the fzf-lua previewer for command-history entries.
---
--- fzf-lua's previewer contract is a shell command string it runs itself, so
--- everything here is a shell string and everything interpolated into one has
--- to be escaped. It previously was not: `:help <topic>` and `:lua <expr>`
--- were pasted in raw, which made a history entry an injection into the
--- previewer's own shell. `cmdlog.ui.preview_policy` rejects an argument that
--- could end the command, and `shellescape` covers the rest.
---
--- What may be previewed how is that module's decision, not this one's: a
--- preview reads, it does not run. See it for why.
---
--- The `:edit` branch shells out to `head`, which is POSIX-only, as is the
--- pipe-to-redir one-liner the other branches need. Rather than emit a broken
--- preview command on Windows, this returns nil there (fzf-lua's "no preview"
--- state). The Telescope previewer (cmdlog.ui.telescope-previewer) reads the
--- file in-process and works everywhere.

local policy = require("cmdlog.ui.preview_policy")

local M = {}

---@internal
---A shell one-liner that renders `vim_cmd` in a throwaway Neovim and prints
---the result. The redirect target is a temp file rather than `output.txt` in
---the cwd, which is where this used to leave one behind on every preview.
---@param label string   shown above the output
---@param vim_cmd string already validated by preview_policy
---@return string
local function via_headless_nvim(label, vim_cmd)
  local out = vim.fn.tempname()
  return string.format(
    "echo %s; nvim -u NONE -c 'redir! > %s | %s | redir END | quit' >/dev/null 2>&1; tail -n 50 %s; rm -f %s",
    vim.fn.shellescape(label),
    vim.fn.shellescape(out),
    vim_cmd,
    vim.fn.shellescape(out),
    vim.fn.shellescape(out)
  )
end

--- Returns a previewer function for fzf-lua.
---
--- `:edit <file>` shows the file's first lines. `:help` and `:lua` have to
--- run something to render anything, so they preview only when
--- `preview_execute` is enabled and the entry passes preview_policy;
--- otherwise the command and the reason are echoed instead.
--- @return fun(entry: string, _: any): string|nil
function M.command_previewer()
  local is_windows = require("lib.nvim.cross.platform.is_windows")()

  return function(entry, _)
    if is_windows then return nil end

    local cmd = entry or ""
    local plan = policy.plan(cmd)

    if plan.kind == "file" and plan.allowed then
      if vim.fn.filereadable(plan.arg) ~= 1 then return nil end
      return string.format("head -n 50 %s", vim.fn.shellescape(plan.arg))
    end

    if not plan.allowed then
      -- One echo per line, so the reason renders as the previewer's output
      -- rather than as a command fzf tries to run.
      local parts = {}
      for _, line in ipairs(policy.explain(cmd, plan)) do
        parts[#parts + 1] = "echo " .. vim.fn.shellescape(line)
      end
      return table.concat(parts, "; ")
    end

    -- The argument lands inside a single-quoted `-c` word, so it has to clear
    -- the shell's quoting as well as Vim's command separator. That check lives
    -- here rather than in the policy because it is this previewer's contract
    -- that creates it: Telescope passes argv and has no shell in the way.
    if not policy.shell_arg_is_safe(plan.arg) then
      return "echo "
        .. vim.fn.shellescape(cmd)
        .. "; echo; echo "
        .. vim.fn.shellescape("Not previewed: the argument would end the quoted command.")
    end

    if plan.kind == "help" then
      return via_headless_nvim(":help " .. plan.arg, "help " .. plan.arg)
    end

    if plan.kind == "lua" then return via_headless_nvim(":lua " .. plan.arg, "lua " .. plan.arg) end

    -- `:terminal` and `:!` have no read-only rendering: previewing them is
    -- running them. The Telescope previewer can stream that into a buffer;
    -- here it would mean handing fzf the command itself, so leave it.
    return nil
  end
end

return M
