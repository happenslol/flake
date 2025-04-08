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
    config = function(_, opts)
      require("util").pairs(opts)
    end,
  },

  {
    "Wansmer/treesj",
    keys = {
      {
        "<leader>s",
        function()
          local tsj_langs = require("treesj.langs")["presets"]
          local lang = require("util").get_pos_lang()
          if lang ~= "" and tsj_langs[lang] then
            require("treesj").toggle()
          else
            require("mini.splitjoin").toggle()
          end
        end,
        desc = "Toggle Split/Join Line",
      },
    },
    opts = { use_default_keymaps = false },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.splitjoin",
    },
    config = true,
  },

  { "tpope/vim-repeat", event = "VeryLazy" },

  {
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    cmd = "GrugFar",
    keys = {
      {
        "grs",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.grug_far({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "v" },
        desc = "Search and Replace",
      },
    },
  },

  {
    "folke/todo-comments.nvim",
    cmd = { "TodoTrouble", "TodoTelescope" },
    event = "VeryLazy",
    opts = {},
    -- stylua: ignore
    keys = {
      { "]t",         function() require("todo-comments").jump_next() end,              desc = "Next Todo Comment" },
      { "[t",         function() require("todo-comments").jump_prev() end,              desc = "Previous Todo Comment" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>",                                   desc = "Todo (Trouble)" },
      { "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
      { "<leader>pt", "<cmd>TodoTelescope<cr>",                                         desc = "Todo" },
      { "<leader>pT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>",                 desc = "Todo/Fix/Fixme" },
    },
  },
}
