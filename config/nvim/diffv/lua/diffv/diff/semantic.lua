--- Treesitter-based semantic diff engine.
--- Diffs at the AST level for structural awareness like difftastic.
local M = {}

--- Compute a semantic diff using treesitter ASTs.
---@param old_text string
---@param new_text string
---@param lang string treesitter language
---@return diffv.DiffResult
function M.diff(old_text, new_text, lang)
  vim.notify("diffv: diff.semantic.diff() not yet implemented", vim.log.levels.INFO)
  return { hunks = {}, old_lines = {}, new_lines = {} }
end

return M
