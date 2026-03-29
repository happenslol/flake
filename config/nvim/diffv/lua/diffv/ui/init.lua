--- Layout manager for diffv views.
--- Creates and destroys diff view layouts (side-by-side or inline).
local M = {}

--- The currently active diff view, if any.
---@type diffv.DiffView?
M.active = nil

--- Create a new diff view.
---@param file_changes diffv.FileChange[]
---@param opts? { layout?: "side_by_side" | "inline" }
---@return diffv.DiffView
function M.create(file_changes, opts)
  vim.notify("diffv: ui.create() not yet implemented", vim.log.levels.INFO)
  ---@type diffv.DiffView
  return {
    buffers = {},
    windows = {},
    file_changes = file_changes,
    current_index = 1,
    config = require("diffv.config").values,
    close = function() end,
  }
end

--- Destroy the active diff view and clean up.
function M.destroy()
  vim.notify("diffv: ui.destroy() not yet implemented", vim.log.levels.INFO)
end

return M
