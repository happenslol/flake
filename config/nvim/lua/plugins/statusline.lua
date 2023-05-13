return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function()
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
          lualine_c = {
            {
              "filename",
              symbols = { modified = "", readonly = "" },
            },
            "diagnostics",
          },
          lualine_x = {
            {
              require("noice").api.status.mode.get_hl,
              cond = require("noice").api.status.mode.has,
            },
            "diff",
          },
          lualine_y = { "branch" },
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {
          },
          lualine_b = {},
          lualine_c = {
            {
              "filename",
              symbols = { modified = "", readonly = "" },
            },
          },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
      }
    end,
  },
}
