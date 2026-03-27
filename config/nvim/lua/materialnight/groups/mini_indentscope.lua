local M = {}

M.url = "https://github.com/echasnovski/mini.indentscope"

---@type materialnight.HighlightsFn
function M.get(c)
  -- stylua: ignore
  return {
    MiniIndentscopeSymbol = { fg = c.fg_gutter, nocombine = true },
    MiniIndentscopePrefix = { nocombine = true }, -- Make it invisible
  }
end

return M
