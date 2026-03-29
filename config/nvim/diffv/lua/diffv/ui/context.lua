--- Context folding for diff views.
--- Hides unchanged lines beyond N lines from the nearest change,
--- with virtual text fold indicators.
local M = {}

--- Apply context folding to a diff buffer.
---@param buf number buffer handle
---@param hunks diffv.Hunk[] parsed hunks (used to determine change boundaries)
---@param context_lines number lines of context to show around changes (0 = show all)
function M.apply(buf, hunks, context_lines)
  vim.notify("diffv: ui.context.apply() not yet implemented", vim.log.levels.INFO)
end

--- Update context level (re-fold with new context line count).
---@param buf number buffer handle
---@param hunks diffv.Hunk[]
---@param delta number change in context lines (+1 or -1)
---@return number new_context the new context line count
function M.adjust(buf, hunks, delta)
  vim.notify("diffv: ui.context.adjust() not yet implemented", vim.log.levels.INFO)
  return 0
end

return M
