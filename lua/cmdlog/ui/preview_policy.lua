---@module 'cmdlog.ui.preview_policy'
--- Decides what a picker is allowed to do to preview a history entry.
---
--- Both previewers (`ui.telescope-previewer`, `ui.fzf-previewer`) used to
--- answer this question inline, and both answered it the same wrong way: they
--- *ran* the entry. Moving the cursor onto `:!rm -rf build` in the picker ran
--- `rm -rf build`; onto `:lua vim.fn.delete(x)` deleted `x` again; onto
--- `:term <cmd>` spawned the command. That is not a preview, and the entries
--- are not necessarily even the user's own: `extra_files` folds arbitrary
--- plain-text files in as history sources, and shell history is folded in too.
---
--- So the rule here is: **a preview reads, it does not run.** Reading a file
--- for `:edit <file>` is a preview. Executing anything is not, and needs
--- `preview_execute = true` — off by default, and refused outright for an
--- entry matching `risky_patterns`, which is the list that already names the
--- destructive commands.
---
--- Arguments are validated here rather than at each call site, because the
--- previewers interpolate them into a Vim `-c` string (where `|` separates
--- commands) and, on the fzf side, into a shell string. `:help x | !cmd` was
--- a working command injection through exactly that path.

local M = {}

---A preview decision.
---@class Cmdlog.PreviewPlan
---@field kind '"file"'|'"help"'|'"lua"'|'"terminal"'|'"shell"'|'"none"'
---@field arg string|nil   the file, topic, expression or command line
---@field executes boolean whether acting on this plan runs something
---@field allowed boolean  whether the caller may act on it
---@field reason string|nil why not, when `allowed` is false

--- What makes an argument dangerous depends on where it is interpolated, so
--- there are two checks rather than one blanket filter. A single filter strict
--- enough for a shell word rejects `vim.fn.getcwd()` for its parentheses --
--- i.e. it turns the feature off rather than making it safe.

--- Ends a Vim command line and starts another one. `|` is the separator; a
--- newline ends the `-c` argument outright.
local VIM_FORBIDDEN = "[|\n\r]"

--- Ends a single-quoted shell word. Inside single quotes nothing else is
--- special to the shell -- not `$`, not a backtick, not a parenthesis -- so
--- forbidding more would only cost legitimate expressions.
local SHELL_FORBIDDEN = "['\n\r]"

---Whether `arg` is safe to interpolate into a Vim `-c` command string.
---
---Help tags are dense in punctuation (`:help v:count`, `:help i_CTRL-W`,
---`:help 'shiftwidth'`), so this cannot be alphanumeric-only.
---@param arg string
---@return boolean
function M.topic_is_safe(arg)
  if type(arg) ~= "string" or arg == "" then return false end
  return arg:find(VIM_FORBIDDEN) == nil
end

---Whether `arg` is safe to interpolate into a single-quoted shell word.
---
---Only the fzf previewer needs this: its contract is a shell string, so its
---`-c` argument sits inside shell quoting that the Telescope previewer, which
---passes argv, never has.
---@param arg string
---@return boolean
function M.shell_arg_is_safe(arg)
  if type(arg) ~= "string" or arg == "" then return false end
  return M.topic_is_safe(arg) and arg:find(SHELL_FORBIDDEN) == nil
end

---@internal
---Classify `cmd` without deciding anything about permission.
---@param cmd string
---@return string kind, string|nil arg
local function classify(cmd)
  local file = cmd:match("^%s*:?%s*e%d?dit%s+(%S+)$")
    or cmd:match("^%s*:?%s*vsp%s+(%S+)$")
    or cmd:match("^%s*:?%s*vs%s+(%S+)$")
  if file then return "file", file end

  local lua_expr = cmd:match("^%s*:?%s*lua%s+(.*)$")
  if lua_expr then return "lua", lua_expr end

  local shell_cmd = cmd:match("^%s*:?%s*!%s*(.*)$")
  if shell_cmd then return "shell", shell_cmd end

  -- `head_word` disambiguates a short abbreviation (":h" for help, ":ter" for
  -- terminal) from an unrelated command sharing the prefix (":hide", ":terse").
  local head_word, tail = cmd:match("^%s*:?%s*(%a+)%s*(.-)$")
  if not head_word then return "none", nil end

  local function is_abbrev_of(word, full, min_len)
    return #word >= min_len and full:sub(1, #word) == word
  end

  if is_abbrev_of(head_word, "help", 1) and tail ~= "" then return "help", tail end
  if is_abbrev_of(head_word, "terminal", 3) then return "terminal", tail ~= "" and tail or nil end

  return "none", nil
end

---What may be done to preview `cmd`.
---@param cmd string
---@return Cmdlog.PreviewPlan
function M.plan(cmd)
  if type(cmd) ~= "string" or cmd == "" then
    return { kind = "none", executes = false, allowed = false }
  end

  local kind, arg = classify(cmd)

  if kind == "none" then return { kind = "none", executes = false, allowed = false } end

  -- Reading the file a `:edit` would open is the one preview that runs
  -- nothing, so it needs no gate.
  if kind == "file" then return { kind = kind, arg = arg, executes = false, allowed = true } end

  -- `:terminal` with no command opens an interactive shell; there is nothing
  -- to preview, and nothing to run either.
  if kind == "terminal" and not arg then
    return { kind = kind, arg = nil, executes = false, allowed = false, reason = "interactive" }
  end

  local plan = { kind = kind, arg = arg, executes = true, allowed = false }

  if not require("cmdlog.config").options.preview_execute then
    plan.reason = "disabled"
    return plan
  end

  -- Second gate, and deliberately not the only one: `risky_patterns` names
  -- the commands whose whole problem is that running them again is
  -- destructive. Highlighting one in the picker and then executing it on
  -- hover would be the plugin contradicting itself.
  if require("cmdlog.core.risky").matching(cmd)[1] then
    plan.reason = "risky"
    return plan
  end

  -- `:help <topic>` is rendered by interpolating the topic into a `-c`
  -- command on both previewers, so it must not be able to end that command.
  -- `:lua <expr>` needs no equivalent here: Telescope evaluates it in-process
  -- through `load`, which is the execution this gate already covers. The fzf
  -- previewer, whose contract is a shell string, applies `shell_arg_is_safe`
  -- itself -- the constraint is its quoting, not this policy's.
  if kind == "help" and not M.topic_is_safe(arg or "") then
    plan.reason = "unsafe-argument"
    return plan
  end

  plan.allowed = true
  return plan
end

---The lines a previewer should show when a plan may not be acted on.
---@param cmd string
---@param plan Cmdlog.PreviewPlan
---@return string[]
function M.explain(cmd, plan)
  local lines = { cmd, "" }

  if plan.reason == "disabled" then
    lines[#lines + 1] = "Preview would run this command. Execution previews are off."
    lines[#lines + 1] = "Enable with: require('cmdlog').setup({ preview_execute = true })"
  elseif plan.reason == "risky" then
    lines[#lines + 1] = "Not previewed: matches risky_patterns."
    lines[#lines + 1] = "Running it again is the thing that list exists to warn about."
  elseif plan.reason == "unsafe-argument" then
    lines[#lines + 1] = "Not previewed: the argument contains characters that would"
    lines[#lines + 1] = "end the command and start another one."
  elseif plan.reason == "interactive" then
    lines[#lines + 1] = "Opens an interactive terminal buffer."
    lines[#lines + 1] = "No static preview available."
  else
    lines[#lines + 1] = "No preview available."
  end

  return lines
end

return M
