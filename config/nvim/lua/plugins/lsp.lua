return {
  {
    "saghen/blink.cmp",
    lazy = false,
    dependencies = "rafamadriz/friendly-snippets",
    build = "nix run .#build-plugin",

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
        ["<C-l>"] = { "snippet_forward", "fallback" },
        ["<C-h>"] = { "snippet_backward", "fallback" },
      },

      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
      },

      sources = {
        default = { "lsp", "path", "snippets", "buffer" },

        -- Disable cmdline completions
        -- cmdline = function()
        --   return {}
        -- end,
      },

      completion = {
        list = { selection = "auto_insert" },
        accept = { auto_brackets = { enabled = true } },

        menu = {
          border = "rounded",
          max_height = 10,
          draw = {
            treesitter = { "lsp" },
            columns = {
              { "label", "label_description", gap = 1 },
              { "kind_icon", "kind", gap = 1 },
            },

            components = {
              kind = { width = { fixed = 8 } },
              label = { width = { min = 12, max = 52 } },
              label_description = { width = { min = 10, max = 30 } },
            },
          },
        },

        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
        },
      },

      signature = { enabled = true },
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
      { "b0o/SchemaStore.nvim", version = false },
      "jose-elias-alvarez/typescript.nvim",
    },
    opts = function()
      return {
        diagnostics = {
          underline = true,
          update_in_insert = false,
          virtual_text = false,
          severity_sort = true,
          float = {
            focused = false,
            style = "minimal",
            border = "rounded",
            source = "always",
            header = "",
            prefix = "",
            max_width = 120,
            max_height = 100,
          },
        },
        servers = {
          jsonls = {
            on_new_config = function(new_config)
              new_config.settings.json.schemas = new_config.settings.json.schemas or {}
              vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
            end,
            settings = {
              json = {
                format = { enable = true },
                validate = { enable = true },
              },
            },
          },
          yamlls = {
            on_new_config = function(new_config)
              new_config.settings.yaml.schemas = new_config.settings.yaml.schemas or {}
              vim.list_extend(new_config.settings.yaml.schemas, require("schemastore").yaml.schemas())
            end,
            settings = { yaml = { keyOrdering = false } },
          },
          vtsls = {
            -- Speed up lsp by requiring the root directory to be a git repo
            root_dir = require("lspconfig.util").root_pattern(".git"),
            settings = {
              complete_function_calls = true,
              vtsls = {
                enableMoveToFileCodeAction = true,
                autoUseWorkspaceTsdk = true,
                experimental = {
                  completion = {
                    enableServerSideFuzzyMatch = true,
                  },
                },
              },
              typescript = {
                updateImportsOnFileMove = { enabled = "always" },
                suggest = { completeFunctionCalls = true },
              },
            },
          },
          lua_ls = {
            settings = {
              Lua = {
                codeLens = { enable = false },
                workspace = { checkThirdParty = false },
                completion = { callSnippet = "Replace" },
              },
            },
          },

          elixirls = {},
          nil_ls = {},

          html = {},
          cssls = {
            settings = {
              css = {
                validate = true,
                lint = { unknownAtRules = "ignore" },
              },
            },
          },
          gopls = {
            settings = {
              gopls = {
                gofumpt = true,
                codelenses = {
                  gc_details = false,
                  generate = true,
                  regenerate_cgo = true,
                  run_govulncheck = true,
                  test = true,
                  tidy = true,
                  upgrade_dependency = true,
                  vendor = true,
                },
                analyses = {
                  fieldalignment = true,
                  nilness = true,
                  unusedparams = true,
                  unusedwrite = true,
                  useany = true,
                },
                usePlaceholders = true,
                completeUnimported = true,
                staticcheck = true,
                directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
                semanticTokens = true,
              },
            },
          },
          taplo = {
            on_attach = function(_, buffer)
              vim.keymap.set("n", "K", function()
                if vim.fn.expand("%:t") == "Cargo.toml" and require("crates").popup_available() then
                  require("crates").show_popup()
                else
                  vim.lsp.buf.hover()
                end
              end, {
                desc = "Show Crate Documentation",
                buffer = buffer,
              })
            end,
          },
          eslint = {},
          zls = {},

          tsp_server = {},
        },
      }
    end,
    config = function(_, opts)
      local util = require("util")
      local lspconfig = require("lspconfig")
      local configs = require("lspconfig.configs")

      util.lsp.setup()

      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      })

      configs.tsp_server = {
        default_config = {
          cmd = { "tsp-server", "--stdio" },
          filetypes = { "typespec" },
          root_dir = lspconfig.util.root_pattern("tspconfig.yaml", ".git"),
          settings = {},
        },
      }

      util.lsp.on_attach(function(client, buffer)
        -- Disable semantic tokens for performance
        client.server_capabilities["semanticTokensProvider"] = nil

        local function map(mode, lhs, rhs, map_opts)
          map_opts = map_opts or {}
          map_opts.buffer = buffer
          map_opts.silent = map_opts.silent ~= false
          vim.keymap.set(mode, lhs, rhs, map_opts)
        end

        map("n", "<leader>lr", "<cmd>LspRestart<cr>", { desc = "Restart LSP" })
        map("n", "<leader>li", "<cmd>LspInfo<cr>", { desc = "Show LSP Info" })

        -- stylua: ignore start
        map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
        map("n", "<leader>c", function() vim.diagnostic.jump({ float = true, count = 1 }) end,
          { desc = "Next Diagnostic" })
        map("n", "<leader>v", function() vim.diagnostic.jump({ float = true, count = -1 }) end,
          { desc = "Previous Diagnostic" })
        map("n", "]d", function() vim.diagnostic.jump({ float = true, count = 1 }) end, { desc = "Next Diagnostic" })
        map("n", "[d", function() vim.diagnostic.jump({ float = true, count = -1 }) end, { desc = "Previous Diagnostic" })
        map("n", "]e", function() vim.diagnostic.jump({ float = true, severity = 1, count = 1 }) end,
          { desc = "Next Diagnostic" })
        map("n", "[e", function() vim.diagnostic.jump({ float = true, severity = 1, count = -1 }) end,
          { desc = "Previous Diagnostic" })
        map("n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration" })
        map("n", "gI", "<cmd>Telescope lsp_implementations<cr>", { desc = "Goto Implementation" })
        map("n", "gt", "<cmd>Telescope lsp_type_definitions<cr>", { desc = "Goto Type" })
        map("n", "gr", "<cmd>Telescope lsp_references<cr>", { desc = "Show References" })
        -- stylua: ignore end

        if client.server_capabilities["signatureHelpProvider"] then
          map("n", "gK", vim.lsp.buf.signature_help, { desc = "Signature Help" })
          map("i", "<c-k>", vim.lsp.buf.signature_help, { desc = "Signature Help" })
        end

        if client.server_capabilities["codeActionProvider"] then
          map({ "n", "v" }, "<leader>a", vim.lsp.buf.code_action, { desc = "Code Actions" })
        end

        if client.server_capabilities["definitionProvider"] then
          map("n", "gd", "<cmd>Telescope lsp_definitions<cr>", { desc = "Goto Definition" })
        end

        if client.server_capabilities["renameProvider"] then
          map("n", "<leader>rr", vim.lsp.buf.rename, { desc = "Rename" })
        end
      end)

      vim.diagnostic.config(opts.diagnostics)

      for server, config in pairs(opts.servers) do
        config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
        lspconfig[server].setup(config)
      end
    end,
  },

  {
    "supermaven-inc/supermaven-nvim",
    cmd = {
      "SupermavenStart",
      "SupermavenStop",
      "SupermavenRestart",
      "SupermavenToggle",
      "SupermavenStatus",
      "SupermavenUseFree",
      "SupermavenUsePro",
      "SupermavenLogout",
      "SupermavenShowLog",
      "SupermavenClearLog",
    },
    event = "InsertEnter",
    config = function()
      require("supermaven-nvim").setup({
        keymaps = {
          accept_suggestion = "<c-j>",
          clear_suggestion = "<c-u>",
          accept_word = "<c-l>",
        },
        color = {
          suggestion_color = "#6f6f6f",
        },
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    lazy = true,
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({
            async = true,
            timeout_ms = 3000,
            quiet = false,
            lsp_format = "first",
            filter = function(client)
              return not vim.tbl_contains({
                "vtsls",
                "gopls",
              }, client.name)
            end,
          })
        end,
        mode = { "n", "v" },
        desc = "Format current buffer",
      },
    },
    ---@module "conform"
    ---@type fun():conform.setupOpts
    opts = function()
      local util = require("util")

      local prettier_fts = {
        "css",
        "graphql",
        "handlebars",
        "html",
        "javascript",
        "javascriptreact",
        "json",
        "jsonc",
        "less",
        "markdown",
        "markdown.mdx",
        "scss",
        "typescript",
        "typescriptreact",
        "vue",
        "yaml",
      }

      local formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt" },
        go = { "goimports", "gofumpt" },
        nix = { "alejandra" },
      }

      for _, ft in ipairs(prettier_fts) do
        if not formatters_by_ft[ft] then
          formatters_by_ft[ft] = {}
        end

        table.insert(formatters_by_ft[ft], "prettierd")
      end

      return {
        formatters_by_ft = formatters_by_ft,
        formatters = {
          prettier = {
            condition = function(_, ctx)
              return util.formatting.has_prettier_config(ctx)
            end,
          },
          eslint_d = {
            condition = function(_, ctx)
              return util.formatting.has_eslint_config(ctx)
            end,
          },
          injected = { options = { ignore_errors = true } },
        },
      }
    end,
  },

  {
    "nvimtools/none-ls.nvim",
    event = "VeryLazy",
    opts = { sources = {} },
  },

  {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      null_ls = {
        enabled = true,
        name = "crates.nvim",
      },
    },
    config = function(_, opts)
      require("crates").setup(opts)
    end,
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^4", -- Recommended
    ft = { "rust" },
    opts = {
      server = {
        on_attach = function(_, bufnr)
          vim.keymap.set("n", "<leader>dr", function()
            vim.cmd.RustLsp("debuggables")
          end, { desc = "Rust Debuggables", buffer = bufnr })
        end,
        default_settings = {
          -- rust-analyzer language server configuration
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = {
                enable = true,
              },
            },
            -- Add clippy lints for Rust.
            checkOnSave = true,
            procMacro = {
              enable = true,
              ignored = {
                ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
                ["async-recursion"] = { "async_recursion" },
              },
            },
          },
        },
      },
    },
    config = function(_, opts)
      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
      if vim.fn.executable("rust-analyzer") == 0 then
        vim.notify("rust-analyzer not found in PATH", vim.log.levels.ERROR)
      end
    end,
  },
}
