require "nvim-treesitter.configs".setup {
  ensure_installed = {
    "bash", "c", "cpp", "css", "cue", "dockerfile",
    "dot", "elixir", "git_rebase", "gitcommit",
    "gitignore", "gitattributes", "go", "gomod", "gosum",
    "gowork", "graphql", "hcl", "heex", "help", "http",
    "ini", "java", "javascript", "jq", "jsdoc", "json",
    "json5", "kotlin", "lua", "luadoc", "make", "nix",
    "rasi", "regex", "rust", "sql", "svelte", "terraform",
    "toml", "tsx", "typescript", "vim", "vue", "yaml",
    "yuck", "zig"
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
