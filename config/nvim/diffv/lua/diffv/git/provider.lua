--- Fetch file contents at specific git revisions.
local M = {}

local git = require("diffv.git")

--- Get file content at a specific revision.
---@param rev string git revision (e.g. "HEAD", "abc123", "HEAD~1")
---@param path string file path relative to repo root
---@param callback fun(content: string?, err: string?)
function M.get_file(rev, path, callback)
  git.run({ "show", rev .. ":" .. path }, nil, function(code, stdout, stderr)
    if code ~= 0 then
      callback(nil, stderr)
    else
      callback(stdout, nil)
    end
  end)
end

--- Get file content at a specific revision synchronously.
--- Use ":" as rev for the index (staged) version.
---@param rev string git revision (e.g. "HEAD", "abc123", ":" for index)
---@param path string file path relative to repo root
---@return string? content
---@return string? err
function M.get_file_sync(rev, path)
  local ref
  if rev == ":" or rev == "" then
    ref = ":" .. path
  else
    ref = rev .. ":" .. path
  end
  local stdout, stderr, code = git.run_sync({ "show", ref })
  if code ~= 0 then
    return nil, stderr
  end
  return stdout, nil
end

--- Get the working copy content of a file.
---@param path string absolute file path
---@return string? content
function M.get_working_copy(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end
  return table.concat(lines, "\n") .. "\n"
end

--- Get the list of changed files between two revisions or working tree.
---@param args string[] git diff arguments (e.g. {}, {"--cached"}, {"HEAD~1..HEAD"})
---@param callback fun(files: { path: string, status: string }[], err: string?)
function M.changed_files(args, callback)
  local cmd = { "diff", "--name-status" }
  for _, a in ipairs(args) do
    cmd[#cmd + 1] = a
  end
  git.run(cmd, nil, function(code, stdout, stderr)
    if code ~= 0 then
      callback({}, stderr)
      return
    end
    local files = {}
    for line in stdout:gmatch("[^\n]+") do
      local status, path = line:match("^(%S+)%s+(.+)$")
      if status and path then
        files[#files + 1] = { path = path, status = status }
      end
    end
    callback(files, nil)
  end)
end

--- Synchronous version of changed_files.
---@param args string[]
---@return { path: string, status: string }[]
---@return string? err
function M.changed_files_sync(args)
  local cmd = { "diff", "--name-status" }
  for _, a in ipairs(args) do
    cmd[#cmd + 1] = a
  end
  local stdout, stderr, code = git.run_sync(cmd)
  if code ~= 0 then
    return {}, stderr
  end
  local files = {}
  for line in stdout:gmatch("[^\n]+") do
    local status, path = line:match("^(%S+)%s+(.+)$")
    if status and path then
      files[#files + 1] = { path = path, status = status }
    end
  end
  return files, nil
end

return M
