return {
  {
    "happenslol/materialnight.nvim",
    lazy = false,
    priority = 1000,
    config = {},
    init = function()
      vim.cmd.colorscheme("materialnight")
    end,
  },
}
