--- Line-level diff engine using vim.diff() (xdiff library).
local M = {}

--- Compute a line-level diff between two strings.
---@param old_text string
---@param new_text string
---@param opts? { algorithm?: "myers" | "patience" | "histogram" }
---@return diffv.DiffResult
function M.diff(old_text, new_text, opts)
  vim.notify("diffv: diff.line.diff() not yet implemented", vim.log.levels.INFO)
  return { hunks = {}, old_lines = {}, new_lines = {} }
end

--- Compute word-level diff within a pair of changed lines.
--- Used for fine-grained DiffText highlighting.
---@param old_line string
---@param new_line string
---@return { old_ranges: number[][], new_ranges: number[][] } changed character ranges
function M.word_diff(old_line, new_line)
  vim.notify("diffv: diff.line.word_diff() not yet implemented", vim.log.levels.INFO)
  return { old_ranges = {}, new_ranges = {} }
end

return M
