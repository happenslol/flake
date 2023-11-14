return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function()
      local name_symbols = {
        modified = "󰤌",
        readonly = "",
      }

      return {
        options = {
          theme = "materialnight",
          globalstatus = false,
          disabled_filetypes = { "neo-tree", "qf" },
          component_separators = { left = "", right = "" },
          section_separators = { left = " ", right = " " },
          refresh = { statusline = 1000 },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "filetype" },
          lualine_c = { { "filename", symbols = name_symbols }, "diagnostics" },
          lualine_x = {
            {
              require("noice").api.status.mode.get_hl,
              cond = require("noice").api.status.mode.has,
            },
            "selectioncount",
            {
              "diff",
              symbols = { added = " ", modified = " ", removed = " " },
            },
          },
          lualine_y = {},
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { { "filename", symbols = name_symbols } },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
      }
    end,
  },
}
