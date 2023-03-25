local util = require "custom.util"
util.bootstrap_packer()

require "custom.plugins"
require "custom.lsp"

util.set_global { mapleader = "," }
util.apply_keymap(require "custom.keymap".global)

util.cmd {
  "filetype plugin indent on",
  "syntax on",
}

