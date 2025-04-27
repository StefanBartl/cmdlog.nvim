local config = require("cmdlog.config")

local M = {}

local supported_shells = {
  zsh = "~/.zsh_history",
  bash = "~/.bash_history",
  fish = "~/.local/share/fish/fish_history",
  nu = "~/.config/nushell/history.txt",
  ksh = "~/.ksh_history",
  csh = "~/.history",
}

--- Returns the name of user used shell
--- @return string
function M.get_shell_name()
  local shell = vim.fn.fnamemodify(vim.env.SHELL or "", ":t")
  if not supported_shells[shell] then
    vim.notify("[nvim-cmdlog]: Unsupported shell '" .. shell .. "'. Supported shells: " .. table.concat(vim.tbl_keys(supported_shells), ", "), vim.log.levels.WARN)
    return ""
  end
  return shell
end

--- Returns the path to the history file of the user used shell
--- @return string
function M.get_shell_history_path()
  local shell = M.get_shell_name()
  if shell == "" then
    return ""
  end

  local path = ""

  if config.options.shell_history_path ~= "default" then
    path = vim.fn.expand(config.options.shell_history_path)
    if not vim.uv.fs_stat(path) then
      vim.notify("[nvim-cmdlog]: Configured shell history file not found at '" .. path .. "'.", vim.log.levels.WARN)
      return ""
    end
    return path
  end

  path = vim.fn.expand(supported_shells[shell])
  if not vim.uv.fs_stat(path) then
    vim.notify("[nvim-cmdlog]: Default shell history file not found at '" .. path .. "'.", vim.log.levels.WARN)
    return ""
  end

  return path
end

--- Returns only the commands of users shell history file
function M.get_shell_history()
  local history = {}
  local path = M.get_shell_history_path()

  if path == "" then
    return history
  end

  local data = vim.fn.readfile(path)
  if not data or vim.tbl_isempty(data) then
    return history
  end

  local shell = M.get_shell_name()
  if shell == "" then
    return history
  end

  for _, line in ipairs(data) do
    if shell == "zsh" then
      local cmd = line:match(";%s*(.*)")
      if cmd and cmd ~= "" then
        table.insert(history, cmd)
      end
    elseif shell == "bash" or shell == "ksh" or shell == "csh" then
      if line ~= "" and not line:match("^#%d+") then
        table.insert(history, line)
      end
    elseif shell == "fish" then
      local cmd = line:match("^%s*%- cmd:%s*(.*)")
      if cmd and cmd ~= "" then
        table.insert(history, vim.fn.json_decode('"' .. cmd .. '"'))
      end
    elseif shell == "nu" then
      if line ~= "" then
        table.insert(history, line)
      end
    else
      vim.notify("[nvim-cmdlog]: Unknown shell format while parsing history.", vim.log.levels.WARN)
      break
    end
  end

  return history
end
