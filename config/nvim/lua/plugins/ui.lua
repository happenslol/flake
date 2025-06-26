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
    },
  },

  {
    "utilyre/sentiment.nvim",
    version = "*",
    config = true,
    event = "VeryLazy",
  },

  {
    "brenoprata10/nvim-highlight-colors",
    event = "VeryLazy",
    config = true,
  },

  {
    "echasnovski/mini.indentscope",
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
