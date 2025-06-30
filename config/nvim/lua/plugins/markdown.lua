---@type LazySpec
return {
  "OXY2DEV/markview.nvim",
  lazy = false,

  opts = {
    preview = { enable = false, icon_provider = "devicons" },
    experimental = { check_rtp = false },
    markdown = { headings = { shift_width = 0 } },
  },
}
