return {
  { "nmac427/guess-indent.nvim", config = true },
  { "kylechui/nvim-surround", config = true, event = "VeryLazy" },
  { "folke/ts-comments.nvim", event = "VeryLazy", opts = {} },

  {
    "echasnovski/mini.pairs",
    event = "VeryLazy",
    opts = {
      modes = { insert = true, command = true, terminal = false },
      -- skip autopair when next character is one of these
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- skip autopair when the cursor is inside these treesitter nodes
      skip_ts = { "string" },
      -- skip autopair when next character is closing pair
      -- and there are more closing pairs than opening pairs
      skip_unbalanced = true,
      -- better deal with markdown code blocks
      markdown = true,
    },
  },

  {
    "Wansmer/treesj",
    keys = { { "<leader>s", "<cmd>TSJToggle<cr>", desc = "Toggle Split/Join Line" } },
    opts = { use_default_keymaps = false },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = true,
  },

  { "tpope/vim-repeat", event = "VeryLazy" },
}
