return {
  {
    "nvim-telescope/telescope.nvim",
    version = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-fzf-native.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
    cmd = "Telescope",
    keys = {
      { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<C-;>", "<cmd>Telescope resume<cr>", desc = "Last Search" },
      {
        "<C-/>",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args()
        end,
        desc = "Live grep",
      },
    },
    opts = function()
      local actions = require("telescope.actions")
      local lga_actions = require("telescope-live-grep-args.actions")

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

          prompt_prefix = "   ",
          selection_caret = "  ",
          entry_prefix = "  ",

          mappings = {
            i = {
              ["<esc>"] = actions.close,
              ["<c-j>"] = actions.move_selection_next,
              ["<c-k>"] = actions.move_selection_previous,
              ["<c-f>"] = actions.preview_scrolling_down,
              ["<c-b>"] = actions.preview_scrolling_up,
              ["<c-w>"] = actions.to_fuzzy_refine,
            },
          },
        },
        extensions = {
          fzf = {},
          live_grep_args = vim.tbl_extend("force", live_grep_config, {
            auto_quoting = true,
            mappings = {
              i = { ["<C-k>"] = lga_actions.quote_prompt() },
            },
          }),
        },
        pickers = {
          find_files = {
            previewer = false,
            sorting_strategy = "ascending",
            layout_config = {
              prompt_position = "top",
              width = 0.4,
              height = 0.6,
            },
          },
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
