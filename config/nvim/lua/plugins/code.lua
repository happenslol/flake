return {
  { "nmac427/guess-indent.nvim", config = true },
  { "kylechui/nvim-surround", config = true, event = "VeryLazy" },

  {
    "windwp/nvim-autopairs",
    lazy = true,
    event = "InsertEnter",
    opts = {
      check_ts = true,
      ts_config = { java = false },
    },
    config = function(_, opts)
      local npairs = require("nvim-autopairs")
      npairs.setup(opts)

      local cmp_status_ok, cmp = pcall(require, "cmp")
      if cmp_status_ok then
        cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done({ tex = false }))
      end
    end,
  },

  {
    "numToStr/Comment.nvim",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    keys = { { "gc", mode = { "n", "v" } }, { "gb", mode = { "n", "v" } } },
    opts = function()
      return { pre_hook = vim.bo.commentstring }
    end,
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
