return {
  {
    "nvim-treesitter/nvim-treesitter",
    version = false,
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "windwp/nvim-ts-autotag" },
    keys = { { "<leader>th", "<cmd>TSBufToggle highlight<cr>", desc = "Toggle TS highlighting" } },
    opts = {
      highlight = {
        enable = true,
        disable = function(_, bufnr)
          return vim.api.nvim_buf_line_count(bufnr) > 10000
        end,
      },
      indent = { enable = true },
      autotag = { enable = true },
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "comment",
        "css",
        "cue",
        "dockerfile",
        "dot",
        "elixir",
        "git_rebase",
        "gitcommit",
        "gitignore",
        "gitattributes",
        "glsl",
        "go",
        "gomod",
        "gosum",
        "gowork",
        "graphql",
        "hcl",
        "heex",
        "html",
        "http",
        "ini",
        "java",
        "javascript",
        "jq",
        "jsdoc",
        "json",
        "jsonc",
        "json5",
        "just",
        "lua",
        "luadoc",
        "make",
        "markdown",
        "markdown_inline",
        "nix",
        "rasi",
        "regex",
        "rust",
        "sql",
        "svelte",
        "terraform",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vue",
        "yaml",
        "yuck",
        "zig",
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.install").prefer_git = true
      require("nvim-treesitter.configs").setup(opts)

      vim.filetype.add({ extension = { tsp = "typespec" } })

      local parser_config = require("nvim-treesitter.parsers").get_parser_configs()

      ---@diagnostic disable-next-line: inject-field
      parser_config.typespec = {
        install_info = {
          url = "~/code/tree-sitter-typespec",
          files = { "src/parser.c" },
        },
        filetype = "typespec",
      }
    end,
  },

  { "JoosepAlviste/nvim-ts-context-commentstring", event = "VeryLazy" },
}
