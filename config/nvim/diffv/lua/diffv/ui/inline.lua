--- Inline (single-buffer) diff renderer.
--- Shows old/new lines interleaved with sign column indicators.
local M = {}

--- Render an inline diff view.
---@param diff_result diffv.DiffResult
---@param filetype string filetype for syntax highlighting
---@return number[] buffers created buffer handles
---@return number[] windows created window handles
function M.render(diff_result, filetype)
  vim.notify("diffv: ui.inline.render() not yet implemented", vim.log.levels.INFO)
  return {}, {}
end

return M
