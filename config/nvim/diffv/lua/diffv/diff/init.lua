--- Diff engine dispatcher.
--- Routes to the appropriate diff strategy (line or semantic).
local M = {}

--- Compute a diff between two strings.
---@param old_text string
---@param new_text string
---@param opts? { algorithm?: "myers" | "patience" | "histogram" }
---@return diffv.DiffResult
function M.diff(old_text, new_text, opts)
  return require("diffv.diff.line").diff(old_text, new_text, opts)
end

return M
