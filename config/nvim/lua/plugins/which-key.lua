return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      marks = true,
      registers = true,
      operators = {},
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

      triggers_nowait = {},

      triggers_blacklist = {
        i = { "j", "k", "q", "@" },
        v = { "j", "k" },
      },

      defaults = {
        ["<space>q"] = { name = "+quickfix" },
        ["<space>w"] = { name = "+loclist" },
        ["<space>g"] = { name = "+git" },
        ["<space>l"] = { name = "+meta" },
        ["<space>m"] = { name = "+messages" },
        ["<space>r"] = { name = "+rename" },
      },
    },
    config = function(_, opts)
      local wk = require("which-key")
      wk.setup(opts)
      wk.register(opts.defaults)
    end,
  },
}
