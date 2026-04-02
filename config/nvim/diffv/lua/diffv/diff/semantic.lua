--- Semantic diff engine (difftastic-style).
--- Implements the diffv.DiffEngine interface.
--- TODO: integrate difftastic's algorithms for AST-aware diffing.
---@class diffv.DiffEngine
local M = {}

--- Compute a semantic diff using AST-level analysis.
---@param old_text string
---@param new_text string
---@param opts? table
---@return diffv.DiffResult
function M.diff(old_text, new_text, opts)
  vim.notify("diffv: semantic diff engine not yet implemented, falling back to line", vim.log.levels.WARN)
  return require("diffv.diff.line").diff(old_text, new_text, opts)
end

--- Compute word-level diff within a pair of changed lines.
---@param old_line string
---@param new_line string
---@return { old_ranges: number[][], new_ranges: number[][] }
function M.word_diff(old_line, new_line)
  return require("diffv.diff.line").word_diff(old_line, new_line)
end

--- Compute the edit distance ratio between two lines.
---@param old_line string
---@param new_line string
---@return number distance 0-1
function M.line_distance(old_line, new_line)
  return require("diffv.diff.line").line_distance(old_line, new_line)
end

return M
