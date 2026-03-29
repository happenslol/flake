--- Review comment data model.
local M = {}

---@class diffv.Comment
---@field file string file path
---@field line number line number in the new version
---@field body string comment text
---@field side "old" | "new" which version the comment refers to
---@field resolved boolean

--- Create a new comment.
---@param file string
---@param line number
---@param body string
---@param side? "old" | "new"
---@return diffv.Comment
function M.new(file, line, body, side)
  vim.notify("diffv: review.comment.new() not yet implemented", vim.log.levels.INFO)
  return { file = file, line = line, body = body, side = side or "new", resolved = false }
end

return M
