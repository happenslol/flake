require "dressing".setup {
  input = { winhighlight = "Normal:Normal,NormalNC:Normal" },
  select = {
    backend = { "telescope", "builtin" },
    builtin = { winhighlight = "Normal:Normal,NormalNC:Normal" },
  },
}
