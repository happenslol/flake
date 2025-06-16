return {
  {
    "happenslol/materialnight.nvim",
    dev = false,
    lazy = false,
    priority = 1000,
    config = {},
    init = function()
      vim.cmd.colorscheme("materialnight")
    end,
  },
}
