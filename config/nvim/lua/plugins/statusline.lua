return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "materialnight",
        globalstatus = false,
        disabled_filetypes = { "neo-tree", "qf" },
        component_separators = { left = "", right = "" },
        section_separators = { left = " ", right = " " },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "filetype" },
        lualine_c = { "filename", "diagnostics" },
        lualine_x = { "diff" },
        lualine_y = { "branch" },
        lualine_z = { "location" },
      },
    },
  },
}
