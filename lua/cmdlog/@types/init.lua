---@meta
---@module 'cmdlog.@types'
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
---@field tag string|false
---@field cycle_source string|false
---@field undo_favorite string|false
---@field move_favorite_up string|false
---@field move_favorite_down string|false

---@class CmdlogExtraFilesConfig
---@field history string[]
---@field all string[]

---@alias CmdlogKeymapsConfig table<string, string>
--- Map of :Cmdlog subcommand name ("" for bare :Cmdlog) to a normal-mode
--- lhs, e.g. `{ [""] = "<leader>ch", favorites = "<leader>cf" }`. Replaced
--- the old fixed-field shape (enabled/cmdlog/cmdlog_full/...) when keymaps
--- moved to a subcommand-derived map -- see cmdlog.bindings.keymaps.

---@class CmdlogProjectScopedConfig
---@field enabled boolean

---@class CmdlogConfig
---@field picker '"telescope"'|'"fzf"'|'"fzf-lua"'
---@field favorites_path string
---@field shell_history_path string|'"default"'
---@field favorite_tags_path string
---@field project_history_path string
---@field stats_path string
---@field errors_path string
---@field track_commands boolean
---@field redact_patterns string[]|false
---@field extra_files CmdlogExtraFilesConfig
---@field project_scoped CmdlogProjectScopedConfig
---@field notes CmdlogNotesConfig
---@field mappings CmdlogMappingsConfig
---@field keymaps CmdlogKeymapsConfig
---@field highlight_risky boolean
---@field risky_patterns string[]|false
