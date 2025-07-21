return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    init = function()
      -- Set an empty statusline until lualine loads
      vim.g.lualine_laststatus = vim.o.laststatus
      vim.o.statusline = " "
    end,
    opts = function()
      -- -- PERF: Remove custom require for lualine
      local lualine_require = require("lualine_require")
      lualine_require.require = require

      -- Restore previous statusline
      vim.o.laststatus = vim.g.lualine_laststatus

      local name_symbols = {
        modified = "󰤌",
        readonly = "",
      }

      return {
        options = {
          theme = "materialnight",
          globalstatus = false,
          disabled_filetypes = {
            "neo-tree",
            "qf",
            "neollm-input",
            "neollm-chat",
          },
          component_separators = { left = "", right = "" },
          section_separators = { left = " ", right = " " },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = {},
          lualine_c = {
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            { "filename", symbols = name_symbols },
            "diagnostics",
          },
          lualine_x = {
            -- stylua: ignore
            {
              function() return require("noice").api.status.command.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
              color = function() return require("util").fg("Statement") end,
            },
            -- stylua: ignore
            {
              function() return require("noice").api.status.mode.get() end,
              cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
              color = function() return require("util").fg("Constant") end,
            },
            {
              "diff",
              symbols = { added = " ", modified = " ", removed = " " },
              source = function()
                local gitsigns = vim.b.gitsigns_status_dict
                if gitsigns then
                  return {
                    added = gitsigns.added,
                    modified = gitsigns.changed,
                    removed = gitsigns.removed,
                  }
                end
              end,
            },
          },
          lualine_y = {},
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { "filename", symbols = name_symbols }, "diagnostics" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },

        extensions = { "neo-tree", "lazy", "nvim-dap-ui", "quickfix" },
      }
    end,
  },
}
