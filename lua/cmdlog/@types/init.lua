---@module 'cmdlog.@types.config'
--- Type definitions for cmdlog configuration.

---@class CmdlogNotesConfig
---@field enabled boolean
---@field format '"markdown"'|'"text"'
---@field dir string
---@field autosave boolean
---@field persist boolean
---@field width number

---@class CmdlogConfig
---@field picker '"telescope"'|'"fzf"'|'"fzf-lua"'
---@field favorites_path string
---@field shell_history_path string|'"default"'
---@field notes CmdlogNotesConfig
