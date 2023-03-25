local tree = require "nvim-tree.config".nvim_tree_callback

require "nvim-tree".setup {
  renderer = {
    group_empty = true,
    icons = {
      show = {
        git = true,
        folder = true,
        file = true,
      },
      glyphs = {
        git = {
          unstaged = "",
          staged = "",
          unmerged = "",
          renamed = "",
          untracked = "",
          deleted = "",
          ignored = "",
        },
      },
    },
  },
  diagnostics = {
    enable = true,
    icons = {
      hint = "",
      info = "",
      warning = "",
      error = "",
    },
  },
  git = {
    enable = true,
    ignore = false,
    timeout = 500
  },
  update_cwd = true,
  actions = {
    open_file = {
      window_picker = {
        enable = true,
        chars = "1234567890",
      },
    }
  },
  view = {
    mappings = {
      custom_only = false,
      list = {
        { key = "s", cb = tree("vsplit") },
        { key = "i", cb = tree("split") },
      },
    },
  },
}
