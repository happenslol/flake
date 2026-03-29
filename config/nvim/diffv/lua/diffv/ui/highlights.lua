--- Extmark-based highlight application for diff buffers.
--- Applies line-level and word-level diff highlighting using the diffv namespace.
local M = {}

--- Apply diff highlights to a buffer using extmarks.
---@param buf number buffer handle
---@param hunks diffv.Hunk[] parsed hunks to highlight
---@param side "old" | "new" | "inline" which side of the diff
function M.apply(buf, hunks, side)
  vim.notify("diffv: ui.highlights.apply() not yet implemented", vim.log.levels.INFO)
end

--- Clear all diffv highlights from a buffer.
---@param buf number buffer handle
function M.clear(buf)
  local ns = require("diffv").ns()
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

return M
