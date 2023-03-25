require "nvim-treesitter.configs".setup {
  indent = { enable = true },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = true,
  },
  autotag = { enable = true },
  context_commentstring = { enable = true },
}

require "util".set_opt {
  foldmethod = "expr",
  foldexpr = "nvim_treesitter#foldexpr()",
  foldenable = false,
  foldlevelstart = 99,
}
