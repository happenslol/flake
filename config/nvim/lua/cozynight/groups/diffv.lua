local M = {}

M.url = ""

---@type cozynight.HighlightsFn
function M.get(c, opts)
  -- stylua: ignore
  return {
    DiffvStatusModified  = { fg = c.git.change },
    DiffvStatusAdded     = { fg = c.git.add },
    DiffvStatusDeleted   = { fg = c.git.delete },
    DiffvStatusRenamed   = { fg = c.git.change },
  }
end

return M
