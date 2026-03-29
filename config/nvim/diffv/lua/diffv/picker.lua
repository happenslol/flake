--- Telescope extension for diffv.
--- Lists changed files with inline diff preview.
local M = {}

--- Open the changed file picker.
---@param opts? { args?: string[] } optional git diff arguments
function M.open(opts)
  vim.notify("diffv: picker.open() not yet implemented", vim.log.levels.INFO)
end

return M
