---@type LazySpec
return {
  {
    "saghen/blink.cmp",
    lazy = false,
    dependencies = {
      "rafamadriz/friendly-snippets",
      "Kaiser-Yang/blink-cmp-avante",
    },
    build = "nix run .#build-plugin",

    ---@module "blink.cmp"
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
      },

      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
      },

      sources = {
        default = {
          "lazydev",
          "avante",
          "lsp",
          "path",
          "snippets",
          "buffer",
        },
        providers = {
          avante = {
            module = "blink-cmp-avante",
            name = "Avante",
            opts = {},
          },

          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            score_offset = 100,
          },
        },
      },

      completion = {
        list = {
          selection = {
            auto_insert = true,
            preselect = function(ctx)
              return ctx.mode ~= "cmdline"
            end,
          },
        },

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
                workspace = { checkThirdParty = true },
                completion = { callSnippet = "Replace" },
              },
            },
          },

          elixirls = { cmd = { "elixir-ls" } },

          nil_ls = {
            settings = {
              ["nil"] = { nix = { flake = { autoArchive = true } } },
            },
          },

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
        jump = {
          float = true,
        },
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

        map("n", "]e", function()
          vim.diagnostic.jump({ float = true, count = 1, severity = vim.diagnostic.severity.ERROR })
        end, { desc = "Next Error" })
        map("n", "[e", function()
          vim.diagnostic.jump({ float = true, count = -1, severity = vim.diagnostic.severity.ERROR })
        end, { desc = "Previous Error" })

        map("n", "gI", "<cmd>Telescope lsp_implementations<cr>", { desc = "Goto Implementation" })
        map("n", "gt", "<cmd>Telescope lsp_type_definitions<cr>", { desc = "Goto Type" })
        map("n", "grr", "<cmd>Telescope lsp_references<cr>", { desc = "Show References" })

        if client.server_capabilities["definitionProvider"] then
          map("n", "gd", "<cmd>Telescope lsp_definitions<cr>", { desc = "Goto Definition" })
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

            -- Only use lsp formatter for eslint
            lsp_format = "first",
            filter = function(client)
              return client.name == "eslint"
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
        "htmldjango",
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

      local biome_fts = {
        "css",
        "graphql",
        "javascript",
        "javascriptreact",
        "json",
        "jsonc",
        "typescript",
        "typescriptreact",
      }

      local formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        go = { "goimports", "gofumpt" },
        nix = { "alejandra" },
      }

      local function insert_formatters(fts, formatter)
        for _, ft in ipairs(fts) do
          if not formatters_by_ft[ft] then
            formatters_by_ft[ft] = {}
          end
          table.insert(formatters_by_ft[ft], formatter)
        end
      end

      insert_formatters(biome_fts, "biome")
      insert_formatters(prettier_fts, "prettierd")

      ---@type table<string, table<string, boolean>>
      local condition_cache = {}
      local function cached(formatter, fn)
        return function(self, ctx)
          if condition_cache[formatter] == nil then
            condition_cache[formatter] = {}
          end

          if condition_cache[formatter][ctx.filename] == nil then
            condition_cache[formatter][ctx.filename] = fn(self, ctx)
          end

          return condition_cache[formatter][ctx.filename]
        end
      end

      ---@type conform.setupOpts
      return {
        default_format_opts = {},
        formatters_by_ft = formatters_by_ft,
        formatters = {
          -- Only use biome if there's no prettier config
          biome = {
            condition = cached("biome", function(_, ctx)
              return not util.formatting.has_prettier_config(ctx)
            end),
          },
          prettierd = {
            condition = cached("prettierd", function(_, ctx)
              -- If we don't have biome, always use prettier
              if not vim.tbl_contains(biome_fts, vim.bo.filetype) then
                return true
              end

              -- If we have biome and no specific prettier config, use biome
              return util.formatting.has_prettier_config(ctx)
            end),
          },
          -- eslint_d = {
          --   condition = cached("eslint_d", function(_, ctx)
          --     return util.formatting.has_eslint_config(ctx)
          --   end),
          -- },
          injected = { options = { ignore_errors = true } },
        },
      }
    end,
  },

  {
    "Saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = { crates = { enabled = true } },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },

  {
    "folke/lazydev.nvim",
    ft = "lua",
    cmd = "LazyDev",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "LazyVim", words = { "LazyVim" } },
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "LazyVim" } },
      },
    },
  },
}
