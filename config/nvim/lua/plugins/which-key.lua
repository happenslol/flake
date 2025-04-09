return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",

      marks = true,
      registers = true,
      show_help = false,

      plugins = {
        presets = {
          operators = false,
          motions = false,
          text_objects = false,
          windows = false,
          nav = false,
          z = false,
          g = false,
        },
      },

      layout = { align = "center" },
      disabled = { filetypes = { "neo-tree" } },
    },
  },
}
