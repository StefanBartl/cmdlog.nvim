---@module 'cmdlog.ui.preview_utils.types'

-- #####################################################################
-- noice_detection.lua

---@class NoiceDetectCache
---@field val boolean|nil  -- cached result
---@field src string|nil   -- where the result came from
---@field ts  integer|nil  -- unix timestamp of cache fill

---@class NoiceDetectOpts
---@field soft boolean|nil  -- if true: never require(); only check package.loaded/globals/heuristics
---@field ttl  integer|nil  -- cache TTL in seconds (default: 2)

-- #####################################################################
-- short_ex.lua

---@class ShortExInfo
---@field label string        -- canonical display of the command (e.g. ":w", ":w!")
---@field help  string|nil    -- help tag to try (e.g. ":w", ":quit", ":bdelete")
---@field desc  string        -- concise human-readable explanation

-- #####################################################################
-- compute_preview_text'

---@class CmdlogPreviewComputeOpts
---@field help_max integer?                     -- default 120
---@field exec_max integer?                     -- default 200
---@field file_max integer?                     -- default 120
---@field bang_max integer?                     -- default 120
---@field allow_messages_with_noice boolean?    -- default false; if false, :messages is blocked when noice.messages active
---@field capture_messages_fn fun():string?     -- optional custom safe-capture for :messages (returns raw text)
---@field shell_info { variant: "powershell"|"cmd"|"posix", exe?: string }? -- optional pre-resolved shell info for :!


