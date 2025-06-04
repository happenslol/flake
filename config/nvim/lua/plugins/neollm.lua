---@type LazySpec
return {
  "happenslol/neollm",
  dependencies = {
    { "OXY2DEV/markview.nvim", lazy = false },
  },
  build = "cargo build --release",
  lazy = false,

  opts = {},
}
