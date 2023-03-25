require "dressing".setup {
  input = { win_options = { winhighlight = "Normal:Normal,NormalNC:Normal" } },
  select = {
    backend = { "nui", "builtin", "telescope" },
    builtin = { win_options = { winhighlight = "Normal:Normal,NormalNC:Normal" } },
    nui = {
      position = {
        row = 2,
        col = 0,
      },
      relative = "cursor",
      min_height = 0,
      min_width = 40,
    },
  },
}
