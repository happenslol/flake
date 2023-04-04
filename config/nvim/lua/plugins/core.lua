return {
  -- Add https://github.com/kevinhwang91/nvim-ufo

  {
    "happenslol/materialnight.nvim",
    config = true,
    init = function() vim.cmd.colorscheme "materialnight" end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      {
        "s1n7ax/nvim-window-picker",
        lazy = true,
        opts = {
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
    init = function() vim.g.neo_tree_remove_legacy_commands = true end,
    opts = {
      window = {
        width = 30,
        mappings = { ["<cr>"] = "open_with_window_picker" },
      },
    },
    keys = {{ "<C-n>", "<cmd>Neotree toggle<cr>", desc = "Neotree" }}
  },

  {
    "nvim-telescope/telescope.nvim",
    version = false,
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope-fzf-native.nvim" },
    cmd = "Telescope",
    keys = {
      { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<C-_>", "<cmd>Telescope live_grep<cr>",  desc = "Live grep" },

    },
    opts = function()
      local telescope_actions = require("telescope.actions")

      return {
        defaults = {
          mappings = {
            i = {
              ["<esc>"] = telescope_actions.close,
              ["<c-j>"] = telescope_actions.move_selection_next,
              ["<c-k>"] = telescope_actions.move_selection_previous,
            }
          },
        }
      }
    end
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
      { "s",  mode = { "n", "x", "o" }, desc = "Leap forward to" },
      { "S",  mode = { "n", "x", "o" }, desc = "Leap backward to" },
      { "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
    },
    config = function(_, opts)
      local leap = require("leap")
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
      leap.add_default_mappings(true)
      vim.keymap.del({ "x", "o" }, "x")
      vim.keymap.del({ "x", "o" }, "X")
    end,
  },

  { "tpope/vim-repeat", event = "VeryLazy" },
}
