---@type LazySpec
return {
  "happenslol/neollm",
  dependencies = { { "OXY2DEV/markview.nvim", lazy = false } },
  build = "nix build",
  lazy = false,

  opts = {},
}
