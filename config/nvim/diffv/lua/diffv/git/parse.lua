--- Parse unified diff output from git into structured data.
local M = {}

--- Parse unified diff output into a list of FileChange records.
---@param diff_output string raw unified diff text
---@return diffv.FileChange[]
function M.parse_diff(diff_output)
  vim.notify("diffv: git.parse.parse_diff() not yet implemented", vim.log.levels.INFO)
  return {}
end

--- Parse a hunk header (@@ -a,b +c,d @@) into numbers.
---@param header string the @@ line
---@return number old_start, number old_count, number new_start, number new_count
function M.parse_hunk_header(header)
  vim.notify("diffv: git.parse.parse_hunk_header() not yet implemented", vim.log.levels.INFO)
  return 0, 0, 0, 0
end

return M
