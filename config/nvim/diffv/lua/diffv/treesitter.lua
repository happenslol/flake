--- Treesitter integration for diffv.
--- Extracts highlights from treesitter on separate file versions
--- and merges them onto conflict-marked or diff buffers.
local M = {}

--- Extract treesitter highlights from a string of code.
---@param code string source code
---@param lang string treesitter language
---@return table[] highlights list of {line, col_start, col_end, hl_group}
function M.extract_highlights(code, lang)
  vim.notify("diffv: treesitter.extract_highlights() not yet implemented", vim.log.levels.INFO)
  return {}
end

--- Merge highlights from two file versions onto a buffer with conflict markers.
---@param buf number buffer handle
---@param ours_highlights table[] highlights for "ours" version
---@param theirs_highlights table[] highlights for "theirs" version
---@param marker_map table mapping from buffer lines to version lines
function M.apply_merged_highlights(buf, ours_highlights, theirs_highlights, marker_map)
  vim.notify("diffv: treesitter.apply_merged_highlights() not yet implemented", vim.log.levels.INFO)
end

return M
