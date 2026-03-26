return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    keys = {
      {
        "<leader>th",
        function()
          if vim.b.ts_highlight then
            vim.treesitter.stop()
          else
            vim.treesitter.start()
          end
        end,
        desc = "Toggle TS highlighting",
      },
    },
    config = function()
      require("nvim-treesitter").setup()

      -- stylua: ignore
      local parsers = {
        "bash", "c", "cpp", "python", "c_sharp", "comment", "css", "cue",
        "dockerfile", "dot", "elixir", "heex", "eex", "git_rebase",
        "gitcommit", "gitignore", "gitattributes", "glsl", "go", "gomod",
        "gosum", "gowork", "graphql", "hcl", "html", "http", "ini", "java",
        "javascript", "jq", "jsdoc", "json", "json5", "just", "lua",
        "luadoc", "make", "markdown", "markdown_inline", "nix", "rasi",
        "regex", "rust", "sql", "svelte", "terraform", "toml", "tsx",
        "typescript", "typespec", "vim", "vue", "yaml", "yuck", "zig",
      }
      require("nvim-treesitter").install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          if vim.api.nvim_buf_line_count(args.buf) > 10000 then
            return
          end
          pcall(vim.treesitter.start, args.buf)
          if vim.treesitter.query.get(vim.bo[args.buf].filetype, "indents") then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  {
    "windwp/nvim-ts-autotag",
    event = "VeryLazy",
    opts = {},
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = { enable = true, mode = "cursor", max_lines = 3 },
    keys = {
      {
        "<leader>ut",
        function()
          local tsc = require("treesitter-context")
          tsc.toggle()
        end,
        desc = "Toggle Treesitter Context",
      },
    },
  },
}
