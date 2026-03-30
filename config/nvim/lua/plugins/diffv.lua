---@type LazySpec
return {
  dir = vim.fn.stdpath("config") .. "/diffv",
  name = "diffv",
  lazy = false,
  keys = {
    { "<leader>cv", "<cmd>DiffV<cr>", desc = "Diff View (side-by-side)" },
    {
      "<leader>ci",
      function()
        require("diffv").open_inline()
      end,
      desc = "Diff View (inline)",
    },
    { "<leader>cs", "<cmd>DiffV --cached<cr>", desc = "Diff View (staged)" },
    {
      "<leader>cf",
      function()
        require("diffv.picker").open()
      end,
      desc = "Diff File Picker",
    },
    {
      "<leader>cr",
      function()
        require("diffv").reload()
      end,
      desc = "Reload diffv",
    },
  },
  opts = {},
  config = function(_, opts)
    require("diffv").setup(opts)
  end,
}
