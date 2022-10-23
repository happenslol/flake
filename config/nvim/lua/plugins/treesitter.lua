require "nvim-treesitter.configs".setup {
  ensure_installed = {
    "lua", "rust", "javascript", "typescript",
    "go", "gomod", "graphql", "html", "css",
    "dockerfile", "json", "json5", "kotlin",
    "java", "markdown", "nix", "rasi", "sql",
    "toml", "tsx", "yaml", "zig"
  },
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
