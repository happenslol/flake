return {
  {
    "stevearc/aerial.nvim",
    opts = {
      attach_mode = "global",
      backends = { "lsp", "treesitter", "markdown", "man" },
      show_guides = true,
      filter_kind = false,

      layout = {
        resize_to_content = false,
        win_opts = {
          -- winhl = "Normal:NormalFloat,FloatBorder:NormalFloat,SignColumn:SignColumnSB",
          signcolumn = "yes",
          statuscolumn = " ",
        },
        guides = {
          mid_item = "├╴",
          last_item = "└╴",
          nested_top = "│ ",
          whitespace = "  ",
        },
      },
    },
    keys = {
      { "<leader>oo", "<cmd>AerialToggle float<cr>", desc = "Aerial Float" },
      { "<leader>oi", "<cmd>AerialToggle<cr>", desc = "Aerial Window" },
      { "<leader>on", "<cmd>AerialNavToggle<cr>", desc = "Aerial Navigation" },
      { "]s", "<cmd>AerialNext<cr>", desc = "Next Symbol" },
      { "[s", "<cmd>AerialNext<cr>", desc = "Previous Symbol" },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },
}
