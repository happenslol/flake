require "window-picker".setup {
  autoselect_one = true,
  include_current = false,
  fg_color = "#212121",
  other_win_hl_color = "#82aaff",
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
