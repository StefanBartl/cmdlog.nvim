---@meta
---@module 'cmdlog.@types.config'
--- Type definitions for cmdlog configuration.

---@class CmdlogNotesConfig
---@field enabled boolean
---@field format '"markdown"'|'"text"'
---@field dir string
---@field autosave boolean
---@field persist boolean
---@field width number

---@class CmdlogMappingsConfig
---@field enabled boolean
---@field select string|false
---@field toggle_favorite string|false
---@field refresh string|false
---@field delete string|false

---@class CmdlogKeymapsConfig
---@field enabled boolean
---@field cmdlog string|nil
---@field cmdlog_full string|nil
---@field favorites string|nil
---@field nvim_history string|nil
---@field nvim_history_full string|nil
---@field shell_history string|nil
---@field shell_history_full string|nil

---@class CmdlogProjectScopedConfig
---@field enabled boolean

---@class CmdlogConfig
---@field picker '"telescope"'|'"fzf"'|'"fzf-lua"'
---@field favorites_path string
---@field shell_history_path string|'"default"'
---@field project_scoped CmdlogProjectScopedConfig
---@field notes CmdlogNotesConfig
---@field mappings CmdlogMappingsConfig
---@field keymaps CmdlogKeymapsConfig
---@field highlight_risky boolean
---@field risky_patterns string[]|false
