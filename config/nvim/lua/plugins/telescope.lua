return {
  {
    "nvim-telescope/telescope.nvim",
    version = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-fzf-native.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
    },
    cmd = "Telescope",
    keys = {
      { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<C-b>", "<cmd>Telescope resume<cr>", desc = "Last Search" },
      { "<C-f>", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
    },
    opts = function()
      local actions = require("telescope.actions")
      local actions_utils = require("telescope.actions.utils")
      local builtin = require("telescope.builtin")

      local lsp_goto_config = {
        layout_strategy = "horizontal",
        sorting_strategy = "ascending",
        layout_config = {
          prompt_position = "top",
          width = 0.7,
          height = 0.6,
        },
      }

      local live_grep_config = {
        only_sort_text = true,
        layout_strategy = "horizontal",
        sorting_strategy = "ascending",
        layout_config = {
          prompt_position = "top",
          width = 0.9,
          height = 0.8,
        },
      }

      local find_files_config = {
        hidden = true,
        file_ignore_patterns = { ".git/" },

        previewer = false,
        sorting_strategy = "ascending",
        layout_config = {
          prompt_position = "top",
          width = 100,
        },
        mappings = {
          i = {
            ["<c-f>"] = function(prompt_bufnr)
              local paths = {}
              actions_utils.map_entries(prompt_bufnr, function(entry)
                table.insert(paths, entry.cwd .. "/" .. entry[1])
              end)

              actions.close(prompt_bufnr)
              builtin.live_grep({
                prompt_title = "Live Grep in Files",
                search_dirs = paths,
              })
            end,
          },
        },
      }

      return {
        defaults = {
          vimgrep_arguments = {
            "rg",
            "-L",
            "--no-heading",
            "--color=never",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
          },

          layout_config = {
            prompt_position = "top",
            width = 0.9,
            height = 0.6,
          },

          prompt_prefix = "   ",
          selection_caret = "  ",
          entry_prefix = "  ",
          results_title = false,

          mappings = {
            i = {
              ["<esc>"] = actions.close,
              ["<c-j>"] = actions.move_selection_next,
              ["<c-k>"] = actions.move_selection_previous,
              ["<c-w>"] = actions.to_fuzzy_refine,
            },
          },
        },
        extensions = {
          fzf = {},
          ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
        },
        pickers = {
          find_files = find_files_config,
          live_grep = live_grep_config,
          quickfix = live_grep_config,
          lsp_definitions = lsp_goto_config,
          lsp_implementations = lsp_goto_config,
          lsp_references = lsp_goto_config,
          lsp_document_symbols = lsp_goto_config,
          lsp_diagnostics = lsp_goto_config,
          lsp_lsp_type_definitions = lsp_goto_config,
        },
      }
    end,
  },
}
