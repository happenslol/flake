return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    keys = { { "<leader>th", "<cmd>TSBufToggle highlight<cr>", desc = "Toggle TS highlighting" } },
    opts = {
      highlight = {
        enable = true,
        disable = function(_, bufnr)
          return vim.api.nvim_buf_line_count(bufnr) > 10000
        end,
      },
      indent = { enable = true },
      -- stylua: ignore
      ensure_installed = {
        "bash", "c", "cpp", "comment", "css", "cue", "dockerfile", "dot",
        "elixir", "heex", "eex", "git_rebase", "gitcommit", "gitignore",
        "gitattributes", "glsl", "go", "gomod", "gosum", "gowork", "graphql",
        "hcl", "html", "http", "ini", "java", "javascript", "jq", "jsdoc",
        "json", "jsonc", "json5", "just", "lua", "luadoc", "make", "markdown",
        "markdown_inline", "nix", "rasi", "regex", "rust", "sql", "svelte",
        "terraform", "toml", "tsx", "typescript", "vim", "vue", "yaml", "yuck",
        "zig",
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "windwp/nvim-ts-autotag",
    event = "VeryLazy",
    opts = {},
  },
}
