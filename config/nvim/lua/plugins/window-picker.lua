require "window-picker".setup {
  autoselect_one = true,
  include_current = false,
  filter_rules = {
    bo = {
      filetype = {
        "neo-tree",
        "neo-tree-popup",
        "notify",
        "quickfix"
      },
      buftype = { "terminal" },
    },
  },
}
