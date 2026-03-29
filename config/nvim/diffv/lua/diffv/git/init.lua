--- Async git command runner.
--- All git interaction goes through this module.
local M = {}

--- Build the full command table for vim.system().
---@param args string[]
---@return string[]
local function build_cmd(args)
  local config = require("diffv.config").values
  local cmd = { config.git_cmd }
  for _, a in ipairs(args) do
    cmd[#cmd + 1] = a
  end
  return cmd
end

--- Run a git command asynchronously.
---@param args string[] git subcommand and arguments
---@param cwd? string working directory (defaults to current)
---@param callback fun(code: number, stdout: string, stderr: string)
function M.run(args, cwd, callback)
  local cmd = build_cmd(args)
  local opts = { text = true }
  if cwd then
    opts.cwd = cwd
  end
  vim.system(cmd, opts, function(result)
    vim.schedule(function()
      callback(result.code, result.stdout or "", result.stderr or "")
    end)
  end)
end

--- Run a git command synchronously (for simple queries).
---@param args string[] git subcommand and arguments
---@param cwd? string working directory
---@return string stdout
---@return string stderr
---@return number code
function M.run_sync(args, cwd)
  local cmd = build_cmd(args)
  local opts = { text = true }
  if cwd then
    opts.cwd = cwd
  end
  local result = vim.system(cmd, opts):wait()
  return result.stdout or "", result.stderr or "", result.code
end

--- Get the git repository root for a given path.
---@param path? string defaults to cwd
---@return string? root nil if not in a git repo
function M.repo_root(path)
  local stdout, _, code = M.run_sync({ "rev-parse", "--show-toplevel" }, path)
  if code ~= 0 then
    return nil
  end
  return vim.trim(stdout)
end

return M
