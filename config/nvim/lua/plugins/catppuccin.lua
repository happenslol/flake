require "catppuccin".setup {
  color_overrides = {
    all = {
      rosewater = "#f2dcd3",
      flamingo = "#8a9b9b",
      pink = "#ff8b92",
      mauve = "#c792ea",
      red = "#ff5370",
      maroon = "#f07178",
      peach = "#f78c6c",
      yellow = "#ffcb6b",
      green = "#c3e88d",
      teal = "#89ddff",
      sky = "#82aaff",
      sapphire = "#9cc4ff",
      blue = "#82aaff",
      lavender = "#ffcb6b",

      text = "#eeffff",
      subtext1 = "#8a9b9b",
      subtext0 = "#7a8d8d",
      overlay2 = "#6c7e7e",
      overlay1 = "#5f6f6f",
      overlay0 = "#515f5f",
      surface2 = "#545454",
      surface1 = "#424242",
      surface0 = "#2f3737",

      base = "#212121",
      mantle = "#2b2b2b",
      crust = "#404040",
    },
  },
}

vim.api.nvim_command "colorscheme catppuccin"
