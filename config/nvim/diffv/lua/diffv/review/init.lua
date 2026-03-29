--- Review session management.
--- Tracks review comments across files in a diff view.
local M = {}

--- Start a new review session.
---@param file_changes diffv.FileChange[]
---@return table session
function M.start(file_changes)
  vim.notify("diffv: review.start() not yet implemented", vim.log.levels.INFO)
  return {}
end

--- Submit the review (create commit or push to remote).
---@param session table
---@param opts? { mode?: "commit" | "remote" }
function M.submit(session, opts)
  vim.notify("diffv: review.submit() not yet implemented", vim.log.levels.INFO)
end

return M
