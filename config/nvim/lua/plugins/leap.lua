return {
  {
    "ggandor/flit.nvim",
    lazy = false,
    dependencies = { "https://codeberg.org/andyg/leap.nvim" },
    keys = function()
      local ret = {}
      for _, key in ipairs({ "f", "F", "t", "T" }) do
        ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
      end
      return ret
    end,
    opts = { labeled_modes = "nx" },
  },

  {
    "https://codeberg.org/andyg/leap.nvim",
    lazy = false,
    keys = {
      { "s", "<Plug>(leap-forward)", mode = { "n", "o" }, desc = "Leap forward" },
      { "S", "<Plug>(leap-backward)", mode = { "n", "o" }, desc = "Leap backward" },
      { "gs", "<Plug>(leap-from-window)", mode = { "n", "o" }, desc = "Leap from windows" },
    },
    config = function(_, opts)
      local leap = require("leap")
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
    end,
  },
}
