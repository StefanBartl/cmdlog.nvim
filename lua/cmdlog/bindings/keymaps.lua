---@module 'cmdlog.bindings.keymaps'
--- Optional normal-mode entry-point keymaps for `:Cmdlog` and its
--- subcommands. Every keymap set here carries a `desc`, so which-key.nvim
--- (v3+) picks it up automatically without any extra registration step.
---
--- Configured as a map of subcommand -> lhs, with `""` meaning bare
--- `:Cmdlog`:
---
---   keymaps = { [""] = "<leader>hc", favorites = "<leader>hf" }
---
--- This replaced a fixed table keyed by the old flat command names when
--- those became `:Cmdlog <subcommand>` routes. Deriving the catalog from
--- `bindings.usrcmds` instead of restating it means a newly added
--- subcommand is mappable immediately, with no second list to update.

local map = require("lib.nvim.bindings.keymap")

local M = {}

--- Mappable targets, derived from the user-command catalog.
--- Keys are subcommand names (`""` for bare `:Cmdlog`), values carry the
--- command to run and the description shown by which-key.
---@return table<string, {cmd: string, desc: string}>
function M.catalog()
  local out = {}
  for _, entry in ipairs(require("cmdlog.bindings.usrcmds").catalog) do
    local key = entry.path or ""
    out[key] = {
      cmd = entry.path and ("Cmdlog " .. entry.path) or "Cmdlog",
      desc = "Cmdlog: " .. entry.desc,
    }
  end
  return out
end

--- Registers the configured keymaps. No-op when `keymaps` is empty.
--- @return nil
function M.register()
  local keymaps = require("cmdlog.config").options.keymaps
  if type(keymaps) ~= "table" or not next(keymaps) then return end

  local catalog = M.catalog()
  local notify = require("lib.nvim.notify.safe").create_safe("[cmdlog.nvim]")

  for key, lhs in pairs(keymaps) do
    if type(lhs) == "string" and lhs ~= "" then
      local entry = catalog[key]
      if entry then
        map("n", lhs, "<cmd>" .. entry.cmd .. "<CR>", { silent = true }, entry.desc)
      else
        -- A typo here would otherwise be a silently dead keymap.
        notify.warn(("keymaps: unknown :Cmdlog subcommand %q — no keymap set"):format(key))
      end
    end
  end
end

return M
