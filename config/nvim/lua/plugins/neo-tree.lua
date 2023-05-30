return {
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
        use_libuv_file_watcher = true,
        filtered_items = {
          visible = true,
          hide_hidden = false,
          hide_dotfiles = false,

          hide_by_pattern = { ".git" },
        },
      },

      default_component_configs = {
        modified = { symbol = "󰤌" },
        git_status = {
          symbols = {
            added = "",
            modified = "",
            deleted = "",
            renamed = "",

            untracked = "",
            ignored = "",
            unstaged = "",
            staged = "",
            conflict = "",
          },
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
}
