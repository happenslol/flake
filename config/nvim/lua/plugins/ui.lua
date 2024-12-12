return {
  { "nvim-tree/nvim-web-devicons", lazy = true },
  { "MunifTanjim/nui.nvim", lazy = true },

  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
      },
      presets = {
        bottom_search = false,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
    },
    keys = {
      {
        "<s-enter>",
        function()
          require("noice").redirect(vim.fn.getcmdline() or "")
          local keys = vim.api.nvim_replace_termcodes("<esc>", true, false, true)
          vim.api.nvim_feedkeys(keys, "n", false)
        end,
        mode = "c",
        desc = "Redirect Cmdline",
      },
      {
        "<leader>ml",
        function()
          require("noice").cmd("last")
        end,
        desc = "Noice Last Message",
      },
      {
        "<leader>mh",
        function()
          require("noice").cmd("history")
        end,
        desc = "Noice History",
      },
      {
        "<leader>ma",
        function()
          require("noice").cmd("all")
        end,
        desc = "Noice All",
      },
      -- {
      --   "<c-f>",
      --   function()
      --     if not require("noice.lsp").scroll(4) then
      --       return "<c-f>"
      --     end
      --   end,
      --   silent = true,
      --   expr = true,
      --   desc = "Scroll forward",
      --   mode = { "i", "n", "s" },
      -- },
      -- {
      --   "<c-b>",
      --   function()
      --     if not require("noice.lsp").scroll(-4) then
      --       return "<c-b>"
      --     end
      --   end,
      --   silent = true,
      --   expr = true,
      --   desc = "Scroll backward",
      --   mode = { "i", "n", "s" },
      -- },
    },
  },

  {
    "utilyre/sentiment.nvim",
    version = "*",
    config = true,
    event = "VeryLazy",
  },

  {
    "stevearc/dressing.nvim",
    lazy = true,
    init = function()
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
      ---@diagnostic disable-next-line: duplicate-set-field
      vim.ui.input = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.input(...)
      end
    end,
    opts = {
      input = {
        default_prompt = "➤ ",
        win_options = { winhighlight = "Normal:Normal,NormalNC:Normal" },
      },
      select = {
        backend = { "telescope" },
        telescope = {
          sorting_strategy = "ascending",
          layout_strategy = "cursor",
          layout_config = {
            width = 80,
            height = 9,
          },
          prompt_title = false,
          results_title = false,
          entry_prefix = "",
          prompt_prefix = "",
          selection_caret = "",
          get_status_text = function()
            return ""
          end,
        },
      },
    },
  },

  {
    "NvChad/nvim-colorizer.lua",
    event = "VeryLazy",
    opts = { user_default_options = { names = false } },
  },

  {
    "echasnovski/mini.indentscope",
    version = false, -- wait till new 0.7.0 release to put it back on semver
    event = "VeryLazy",
    opts = function()
      local indentscope = require("mini.indentscope")

      return {
        symbol = "│",
        options = { try_as_border = true },
        draw = {
          delay = 50,
          animation = indentscope.gen_animation.linear({
            duration = 100,
            unit = "total",
          }),
        },
      }
    end,
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "alpha",
          "dashboard",
          "fzf",
          "help",
          "lazy",
          "lazyterm",
          "mason",
          "neo-tree",
          "notify",
          "toggleterm",
          "Trouble",
          "trouble",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },
}
