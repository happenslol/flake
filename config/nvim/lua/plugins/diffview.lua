---@type LazySpec
return {
  "sindrets/diffview.nvim",
  event = "VeryLazy",
  opts = {
    show_help_hints = false,
    enhanced_diff_hl = true,

    view = {
      default = { disable_diagnostics = true },
      file_history = { disable_diagnostics = true },
    },
  },
}
