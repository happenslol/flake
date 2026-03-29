--- Fetch file contents at specific git revisions.
local M = {}

--- Get file content at a specific revision.
---@param rev string git revision (e.g. "HEAD", "abc123", "HEAD~1")
---@param path string file path relative to repo root
---@param callback fun(content: string?, err: string?)
function M.get_file(rev, path, callback)
  vim.notify("diffv: git.provider.get_file() not yet implemented", vim.log.levels.INFO)
end

--- Get the working copy content of a file.
---@param path string absolute or repo-relative file path
---@return string? content
function M.get_working_copy(path)
  vim.notify("diffv: git.provider.get_working_copy() not yet implemented", vim.log.levels.INFO)
  return nil
end

return M
