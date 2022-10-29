local util = require "util"

util.set_global {
  material_theme_style = "darker",
  material_terminal_italics = 1,
}

vim.cmd.colorscheme("material")
