---@module 'cmdlog.ui.preview_utils.compute_preview_text'

local common = require("cmdlog.ui.preview_utils.common")

--- Compute the preview text for a single command.
--- Keeps feature-parity between Telescope and fzf-lua.
---@nodiscard
---@param raw_cmd string
---@param opts CmdalogPreviewComputeOpts|nil
---@return string
return function(raw_cmd, opts)
  opts = opts or {}
  local help_max = opts.help_max or 120
  local exec_max = opts.exec_max or 200
  local file_max = opts.file_max or 120
  local bang_max = opts.bang_max or 120

  local excmds   = require("cmdlog.ui.preview_utils.excommands_utils")
  local short_ex = require("cmdlog.ui.preview_utils.short_ex")
  local echo     = require("cmdlog.ui.preview_utils.echo")
  local help     = require("cmdlog.ui.preview_utils.help")
  local usercmd  = require("cmdlog.ui.preview_utils.usercommands")
  local noice    = require("cmdlog.ui.preview_utils.noice_detection")
  local shell_u  = require("cmdlog.ui.preview_utils.shell")

  local cmd = common.unwrap_cmd(raw_cmd)
  local exhead = (excmds.ex_head_after_mods(cmd) or ""):lower()

  -- :help {topic}
  do
    if exhead == "help" or exhead == "h" then
      local topic = cmd:match("^%s*:?%s*he?lp%s+(.+)$")
      if topic then
        return help.try_preview(topic, help_max) or "[no preview] for this help tag"
      end
    end
  end

  -- :echo ...
  do
    local e = echo.try_preview(cmd)
    if e ~= nil then
      return e ~= "" and e or "[empty echo]"
    end
  end

  -- :{user-command} (global/buffer)
  do
    local u = usercmd.try_preview(cmd)
    if u and u ~= "" then
      return u
    end
  end

  -- Introspection & safe Ex (incl. :messages)
  if excmds.SAFE[exhead] or excmds.is_messages_ex(cmd) then
    if exhead == "messages" then -- AUDIT: silent messages ?
      local noice_active = noice.is_noice_messages_enabled({ soft = true })
      if noice_active then
        return "[no preview] ':messages' preview disabled while 'noice.messages' is active"
      end
      return common.exec_preview_text("silent messages", exec_max)
    end
    return common.exec_preview_text(cmd, exec_max)
  end

  -- Short Ex ("w", "q", "bd", ...)
  do
    local explained = short_ex.try_preview(cmd)
    if explained and explained ~= "" then
      return explained
    end
  end

  -- File previews via edit-like commands
  do
    local file = common.extract_file_from_edit(cmd)
    if file and common.is_readable(file) then
      return common.file_preview_text(file, file_max)
    end
  end

  -- :!bang (portable wrapper) AUDIT: Reallky both os?
  do
    local bang = cmd:match("^%s*:?%s*!%s*(.+)$")
    if bang and bang ~= "" then
      local variant, exe
      if opts.shell_info and type(opts.shell_info) == "table" then
        variant = opts.shell_info.variant or "posix"
        exe = opts.shell_info.exe
      else
        -- Resolve lazily only when needed
        local core_shell = require("cmdlog.core.shell")
        local info = core_shell.get_shell_info()
        variant = (info and info.variant) or "posix"
        exe = (info and info.exe)
          or (variant == "powershell" and "powershell"
            or (variant == "cmd" and "cmd" or "sh"))
      end
      return shell_u.bang_preview_text(exe, variant, bang, bang_max)
    end
  end

  return "[no preview]"
end
