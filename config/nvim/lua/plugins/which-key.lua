return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
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
    config = function(_, opts)
      -- TODO: Get this to work
      -- Show registers when pressing remapped ' key
      local registers = require("which-key.plugins.registers")
      table.insert(registers.mappings, { "'", mode = { "n", "x" }, desc = "registers" })

      local wk = require("which-key")
      wk.setup(opts)
      wk.add({
        { "<space>g", group = "git" },
        { "<space>q", group = "quickfix" },
        { "<space>w", group = "loclist" },
        { "<space>l", group = "meta" },
        { "<space>m", group = "messages" },
        { "<space>r", group = "rename" },
      })
    end,
  },
}
