local util = require "util"

util.set_global {
  material_theme_style = "darker",
  material_terminal_italics = 1,
}

_G.colors = util.extract_colors(vim.g.material_colorscheme_map)
vim.cmd.colorscheme("material")
