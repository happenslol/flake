---@type LazySpec
return {
  {
    "saghen/blink.cmp",
    lazy = false,
    version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" },

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
          "lsp",
          "path",
          "snippets",
          "buffer",
        },
        providers = {
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
        },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      { "b0o/SchemaStore.nvim", version = false },
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
            source = "always",
            header = "",
            prefix = "",
            max_width = 120,
            max_height = 100,
          },
        },
        servers = {
          jsonls = {
            -- lazy-load schemastore when needed
            before_init = function(_, new_config)
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
            -- yamlls needs this to know we support line folding
            capabilities = {
              textDocument = {
                foldingRange = {
                  dynamicRegistration = false,
                  lineFoldingOnly = true,
                },
              },
            },
            -- lazy-load schemastore when needed
            before_init = function(_, new_config)
              new_config.settings.yaml.schemas = vim.tbl_deep_extend(
                "force",
                new_config.settings.yaml.schemas or {},
                require("schemastore").yaml.schemas()
              )
            end,
            settings = {
              yaml = {
                keyOrdering = false,
                -- disable built-in schema fetching in favor of SchemaStore.nvim
                schemaStore = { enable = false, url = "" },
              },
            },
          },
          vtsls = {
            -- Speed up lsp by requiring the root directory to be a git repo
            -- TODO: This doesn't work anymore, do we still need the speed?
            -- root_dir = require("lspconfig.util").root_pattern(".git"),
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
          denols = {
            -- denols and vtsls never attach to the same buffer: lspconfig's
            -- root_dir for both compares the nearest deno.json/deno.lock with
            -- the nearest package manager lockfile, and the closer one wins.
            settings = {
              deno = {
                lint = true,
              },
            },
            -- oxlint/oxfmt replace the deno toolchain where they are configured
            -- (see plugins/conform.lua), so deno's lint rules would only fight
            -- them. Type errors keep coming from deno either way.
            before_init = function(params, config)
              config.settings.deno.lint = not require("util.webtools").ox_overrides_deno(params.rootPath)
            end,
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
          oxlint = {
            root_dir = function(bufnr, on_dir)
              -- prefer the top-level oxlint config if it exists (monorepo support)
              local markers = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" }
              local git = vim.fs.root(bufnr, ".git")
              local root = git and vim.fs.root(git, markers) or vim.fs.root(bufnr, markers)
              if root then
                on_dir(root)
              end
            end,
            settings = { fixKind = "all" },
          },
          zls = {},

          tsp_server = {},
        },
      }
    end,
    config = vim.schedule_wrap(function(_, opts)
      vim.diagnostic.config({
        jump = { float = true },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      })

      vim.lsp.config("tsp_server", {
        cmd = { "tsp-server", "--stdio" },
        filetypes = { "typespec" },
        root_markers = { "tspconfig.yaml", ".git" },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("custom_lsp_attach", { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then
            return
          end
          local buffer = args.buf

          -- Disable semantic tokens for performance
          client.server_capabilities["semanticTokensProvider"] = nil

          local function map(mode, lhs, rhs, map_opts)
            map_opts = map_opts or {}
            map_opts.buffer = buffer
            map_opts.silent = map_opts.silent ~= false
            vim.keymap.set(mode, lhs, rhs, map_opts)
          end

          map("n", "]e", function()
            vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
          end, { desc = "Next Error" })
          map("n", "[e", function()
            vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
          end, { desc = "Previous Error" })

          map("n", "gI", function()
            Snacks.picker.lsp_implementations()
          end, { desc = "Goto Implementation" })
          map("n", "gt", function()
            Snacks.picker.lsp_type_definitions()
          end, { desc = "Goto Type" })
          map("n", "grr", function()
            Snacks.picker.lsp_references()
          end, { desc = "Show References" })

          if client:supports_method("textDocument/definition") then
            map("n", "gd", function()
              Snacks.picker.lsp_definitions()
            end, { desc = "Goto Definition" })
          end
        end,
      })

      -- Prefer LSP folds over the treesitter foldexpr fallback when the server
      -- provides them (handles dynamically registered capabilities too)
      Snacks.util.lsp.on({ method = "textDocument/foldingRange" }, function(buf)
        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
          vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
        end
      end)

      vim.diagnostic.config(opts.diagnostics)

      local servers = {}
      for server, config in pairs(opts.servers) do
        config.capabilities = require("blink.cmp").get_lsp_capabilities(config.capabilities)
        vim.lsp.config(server, config)
        servers[#servers + 1] = server
      end

      -- Enable all configured LSPs
      vim.lsp.enable(servers)
    end),
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
        { path = "snacks.nvim", words = { "Snacks" } },
        { path = "lazy.nvim", words = { "LazySpec" } },
      },
    },
  },
}
