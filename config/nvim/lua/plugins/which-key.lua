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
        n = { "d", "c" },
        i = { "j", "k", "q", "@" },
        v = { "j", "k" },
      },
    },
    config = function(_, opts)
      -- TODO: Get this to work
      -- Show registers when pressing remapped ' key
      local registers_actions = require("which-key.plugins.registers").actions
      table.insert(registers_actions, { trigger = "'", mode = "n" })
      table.insert(registers_actions, { trigger = "'", mode = "v" })

      local wk = require("which-key")
      wk.setup(opts)
      wk.register({
        ["<space>g"] = { name = "+git" },
        ["<space>q"] = { name = "+quickfix" },
        ["<space>w"] = { name = "+loclist" },
        ["<space>l"] = { name = "+meta" },
        ["<space>m"] = { name = "+messages" },
        ["<space>r"] = { name = "+rename" },
      })
    end,
  },
}
