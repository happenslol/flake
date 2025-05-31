---@type LazySpec
return {
  "OXY2DEV/markview.nvim",
  lazy = false,

  opts = {
    preview = { enable = false, icon_provider = "devicons" },
    markdown = {
      headings = {
        shift_width = 0,
      },
    },
  },
}
