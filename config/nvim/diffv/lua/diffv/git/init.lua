--- Async git command runner.
--- All git interaction goes through this module.
local M = {}

--- Run a git command asynchronously.
---@param args string[] git subcommand and arguments
---@param cwd? string working directory (defaults to current)
---@param callback fun(code: number, stdout: string, stderr: string)
function M.run(args, cwd, callback)
  vim.notify("diffv: git.run() not yet implemented", vim.log.levels.INFO)
end

--- Run a git command synchronously (for simple queries).
---@param args string[] git subcommand and arguments
---@param cwd? string working directory
---@return string stdout
---@return string stderr
---@return number code
function M.run_sync(args, cwd)
  vim.notify("diffv: git.run_sync() not yet implemented", vim.log.levels.INFO)
  return "", "", 1
end

return M
