local M = {}

M.url = "https://github.com/folke/snacks.nvim"

---@type cozynight.HighlightsFn
function M.get(c, opts)
  -- stylua: ignore
  return {
    SnacksPicker                  = { bg = c.bg_float },
    SnacksPickerBorder            = { fg = c.bg_float, bg = c.bg_float },
    SnacksPickerInput             = { fg = c.fg, bg = c.bg_float },
    SnacksPickerInputBorder       = { fg = c.bg_float, bg = c.bg_float },
    SnacksPickerInputPrefix       = { fg = c.blue, bg = c.bg_float },
    SnacksPickerInputTitle        = { fg = c.bg, bg = c.blue },
    SnacksPickerList              = { bg = c.bg_float },
    SnacksPickerListBorder        = { fg = c.bg_float, bg = c.bg_float },
    SnacksPickerListTitle         = { fg = c.bg_float, bg = c.bg_float },
    SnacksPickerPreview           = { bg = c.bg_float },
    SnacksPickerPreviewBorder     = { fg = c.bg_float, bg = c.bg_float },
    SnacksPickerPreviewTitle      = { fg = c.bg_float, bg = c.green },
    SnacksPickerDir               = { fg = c.comment },
    SnacksPickerTotals            = { fg = c.comment },
    SnacksPickerGitStatusAdded    = { fg = c.green },
    SnacksPickerGitStatusModified = { fg = c.yellow },
    SnacksPickerGitStatusDeleted  = { fg = c.red },
    SnacksPickerGitStatusUntracked = { fg = c.comment },
  }
end

return M
