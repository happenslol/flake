--- Scratch buffer lifecycle management for diffv.
--- Creates filetype-aware scratch buffers and tracks them for cleanup.
local M = {}

--- Active diffv buffers
---@type number[]
M.buffers = {}

--- Create a scratch buffer configured for displaying diff content.
---@param filetype? string filetype for syntax highlighting
---@return number buf buffer handle
function M.create(filetype)
  vim.notify("diffv: buffer.create() not yet implemented", vim.log.levels.INFO)
  return -1
end

--- Wipe all tracked diffv buffers.
function M.cleanup()
  vim.notify("diffv: buffer.cleanup() not yet implemented", vim.log.levels.INFO)
end

return M
