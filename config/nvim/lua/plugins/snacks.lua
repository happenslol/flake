return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,

  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    explorer = { enabled = true },
    indent = { enabled = false },
    input = { enabled = true },
    picker = { enabled = true },
    notifier = { enabled = false },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
  },
}
