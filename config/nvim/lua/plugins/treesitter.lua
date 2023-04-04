return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    ---@type TSConfig
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      context_commentstring = { enable = true, enable_autocmd = false },
      ensure_installed = {
        "bash", "c", "cpp", "css", "cue", "dockerfile",
        "dot", "elixir", "git_rebase", "gitcommit",
        "gitignore", "gitattributes", "go", "gomod", "gosum",
        "gowork", "graphql", "hcl", "heex", "help", "http",
        "ini", "java", "javascript", "jq", "jsdoc", "json", "jsonc",
        "json5", "kotlin", "lua", "luadoc", "make", "markdown",
        "markdown_inline", "nix", "rasi", "regex", "rust", "sql",
        "svelte", "terraform", "toml", "tsx", "typescript",
        "vim", "vue", "yaml", "yuck", "zig"
      },
    },
    ---@param opts TSConfig
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  { "JoosepAlviste/nvim-ts-context-commentstring", lazy = true },

  {
    "nvim-treesitter/playground",
    event = "VeryLazy",
  },
}
