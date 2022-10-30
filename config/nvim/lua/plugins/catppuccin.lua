require "catppuccin".setup {
  color_overrides = {
    all = {
      rosewater = "#f2dcd3",
      flamingo = "#ddffa7",
      pink = "#f274bc",
      mauve = "#e1acff",
      red = "#f07178",
      maroon = "#ff8b92",
      peach = "#ffcb6b",
      yellow = "#ffe585",
      green = "#c3e88d",
      teal = "#89ddff",
      sky = "#a3f7ff",
      sapphire = "#9cc4ff",
      blue = "#82aaff",
      lavender = "#c792ea",

      text = "#eeffff",
      subtext1 = "#BAC2DE",
      subtext0 = "#A6ADC8",
      overlay2 = "#9399B2",
      overlay1 = "#7F849C",
      overlay0 = "#6C7086",
      surface2 = "#585B70",
      surface1 = "#45475A",
      surface0 = "#313244",

      base = "#212121",
      mantle = "#2b2b2b",
      crust = "#404040",
    },
  },
}

vim.api.nvim_command "colorscheme catppuccin"
