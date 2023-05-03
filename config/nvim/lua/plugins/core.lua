return {
  -- Add https://github.com/kevinhwang91/nvim-ufo

  {
    "happenslol/materialnight.nvim",
    config = true,
    init = function()
      vim.cmd.colorscheme("materialnight")
    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      {
        "s1n7ax/nvim-window-picker",
        lazy = true,
        opts = {
          other_win_hl_color = "#415580",
          fg_color = "#eeffff",
          include_current = false,
          autoselect_one = true,
          filter_rules = {
            bo = {
              filetype = { "neo-tree", "neo-tree-popup", "notify" },
              buftype = { "terminal", "quickfix" },
            },
          },
        },
      },
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
    },
    cmd = "Neotree",
    init = function()
      vim.g.neo_tree_remove_legacy_commands = true
    end,
    opts = {
      window = {
        width = 30,
        mappings = {
          ["<cr>"] = "open_with_window_picker",
          ["o"] = "open_with_window_picker",
          ["l"] = false,
        },
      },
      filesystem = {
        filtered_items = {
          visible = true,
        },
      },
    },
    keys = {
      {
        "<c-n>",
        "<cmd>Neotree toggle<cr>",
        desc = "Neotree",
      },
      {
        "<leader>n",
        "<cmd>Neotree focus reveal<cr>",
        desc = "View Current File in Neotree",
      },
    },
  },

  {
    "ggandor/flit.nvim",
    dependencies = { "ggandor/leap.nvim" },
    keys = function()
      local ret = {}
      for _, key in ipairs({ "f", "F", "t", "T" }) do
        ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
      end
      return ret
    end,
    opts = { labeled_modes = "nx" },
  },

  {
    "ggandor/leap.nvim",
    keys = {
      { "s", "<Plug>(leap-forward-to)", mode = { "n", "o" }, desc = "Leap forward to" },
      { "S", "<Plug>(leap-backward-to)", mode = { "n", "o" }, desc = "Leap backward to" },
      { "x", "<Plug>(leap-forward-till)", mode = { "x" }, desc = "Leap forward until" },
      { "X", "<Plug>(leap-backward-till)", mode = { "x" }, desc = "Leap backward until" },
      { "gs", "<Plug>(leap-from-window)", mode = { "n", "o" }, desc = "Leap from windows" },
    },
    config = function(_, opts)
      local leap = require("leap")
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
    end,
  },

  { "tpope/vim-repeat", event = "VeryLazy" },
}
