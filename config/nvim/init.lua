local util = require "util"
util.bootstrap_packer()

require "plugins"
require "theme"
require "lsp"

util.apply_keymap(require "keymaps".global_keymap)

vim.cmd [[filetype plugin indent on]]
vim.cmd [[syntax on]]

util.set_opt {
  modeline = true,
  modelines = 5,

  mouse = "a",

  -- TODO: Re-enable this as soon
  -- as the confirmation prompt is fixed
  -- cmdheight = 0,

  pumheight = 10,

  showmode = false,
  laststatus = 3,

  number = true,
  numberwidth = 4,
  signcolumn = "yes",

  clipboard = "unnamedplus",
  wildmenu = true,
  backspace = "indent,eol,start",
  fileencoding = "utf-8",

  binary = true,
  endofline = false,
  startofline = false,
  winminheight = 0,

  title = true,
  titlestring = "nvim | %{substitute(getcwd(), $HOME, '~', '')}",

  hlsearch = true,
  ignorecase = true,
  smartcase = true,
  incsearch = true,
  inccommand = "nosplit",
  errorbells = false,
  ruler = true,
  shortmess = "atIO",
  showcmd = true,
  scrolloff = 8,
  fillchars = { eob = " " },

  lazyredraw = true,
  termguicolors = true,

  expandtab = true,
  tabstop = 2,
  shiftwidth = 2,

  preserveindent = true,

  writebackup = false,
  swapfile = false,
  undofile = true,
  undodir = vim.fn.stdpath("data") .. "/undo",

  updatetime = 250,
}
