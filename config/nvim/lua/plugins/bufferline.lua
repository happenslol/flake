---@type LazySpec
return {
  "akinsho/bufferline.nvim",
  event = "VeryLazy",
  version = "*",
  dependencies = "nvim-tree/nvim-web-devicons",
  opts = {
    options = {
      mode = "tabs",
      always_show_bufferline = false,
      show_close_icon = false,
      show_buffer_close_icons = false,
      show_buffer_icons = false,
      hover = { enabled = false },
    },

    highlights = {
      fill = { bg = "#212121" },
    },
  },
}
