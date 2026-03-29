--- Side-by-side diff renderer.
--- Creates a vertical split with old version (left) and new version (right),
--- with line padding for alignment and synchronized scrolling.
local M = {}

--- Render a side-by-side diff view.
---@param diff_result diffv.DiffResult
---@param filetype string filetype for syntax highlighting
---@return number[] buffers created buffer handles
---@return number[] windows created window handles
function M.render(diff_result, filetype)
  vim.notify("diffv: ui.side_by_side.render() not yet implemented", vim.log.levels.INFO)
  return {}, {}
end

return M
