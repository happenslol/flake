local M = {}

M.url = "https://github.com/nvim-telescope/telescope.nvim"

---@type materialnight.HighlightsFn
function M.get(c, opts)
  local t = {
    prompt_bg = c.bg_highlight,
    prompt_fg = c.fg,
    prompt_title_fg = c.bg,
    results_bg = c.bg_float,
    prompt_accent = c.blue,
    preview_accent = c.green,
  }

  -- stylua: ignore
  return {
    TelescopeBorder = { fg = t.prompt_bg, bg = t.results_bg },
    TelescopeNormal = { bg = t.results_bg },
    TelescopePreviewBorder = { fg = t.results_bg, bg = t.results_bg },
    TelescopePreviewNormal = { bg = t.results_bg },
    TelescopePreviewTitle = { fg = t.results_bg, bg = t.preview_accent },
    TelescopePromptBorder = { fg = t.prompt_bg, bg = t.prompt_bg },
    TelescopePromptNormal = { fg = t.prompt_fg, bg = t.prompt_bg },
    TelescopePromptPrefix = { fg = t.prompt_accent, bg = t.prompt_bg },
    TelescopePromptCounter = { fg = c.comment },
    TelescopePromptTitle = { fg = t.prompt_title_fg, bg = t.prompt_accent },
    TelescopeResultsBorder = { fg = t.results_bg, bg = t.results_bg },
    TelescopeResultsNormal = { bg = t.results_bg },
    TelescopeResultsTitle = { fg = t.results_bg, bg = t.results_bg },
    TelescopeResultsDiffAdd = { fg = c.green},
    TelescopeResultsDiffChange = { fg = c.yellow },
    TelescopeResultsDiffDelete = { fg = c.red },
    TelescopeResultsDiffUntracked = { fg = c.comment },
  }
end

return M
