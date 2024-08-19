return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
    },
    cmd = "Neotree",
    opts = {
      open_files_do_not_replace_types = { "terminal", "Trouble", "trouble", "qf", "Outline" },
      window = {
        width = 30,
        mappings = {
          ["<cr>"] = "open",
          ["o"] = "open",
          ["l"] = false,
          ["Y"] = {
            function(state)
              local node = state.tree:get_node()
              local path = node:get_id()
              vim.fn.setreg("+", path, "c")
            end,
            desc = "Copy Path to Clipboard",
          },
          ["O"] = {
            function(state)
              require("lazy.util").open(state.tree:get_node().path, { system = true })
            end,
            desc = "Open with System Application",
          },
        },
      },
      filesystem = {
        use_libuv_file_watcher = true,
        filtered_items = {
          visible = false,
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
