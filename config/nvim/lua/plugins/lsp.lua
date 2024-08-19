return {
  {
    "L3MON4D3/LuaSnip",
    -- TODO: Add friendly-snippets back
    lazy = true,
    opts = {
      history = true,
      delete_check_events = "TextChanged",
    },
  },

  {
    "hrsh7th/nvim-cmp",
    version = false,
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      "onsails/lspkind.nvim",
    },
    opts = function()
      local cmp = require("cmp")
      local cmp_select_next = function(fallback)
        local luasnip = require("luasnip")
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end

      local cmp_select_prev = function(fallback)
        local luasnip = require("luasnip")
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end

      local border_opts = {
        border = "rounded",
        winhighlight = "Normal:Normal,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
      }

      return {
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        window = {
          completion = cmp.config.window.bordered(border_opts),
          documentation = cmp.config.window.bordered(border_opts),
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<tab>"] = cmp_select_next,
          ["<down>"] = cmp_select_next,
          ["<s-tab>"] = cmp_select_prev,
          ["<up>"] = cmp_select_prev,
          ["<c-b>"] = cmp.mapping.scroll_docs(-4),
          ["<c-f>"] = cmp.mapping.scroll_docs(4),
          ["<c-space>"] = cmp.mapping.complete(),
          ["<c-d>"] = cmp.mapping.abort(),
          ["<cr>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = false,
          }),
        }),
        duplicates = {
          nvim_lsp = 1,
          luasnip = 1,
          buffer = 1,
          path = 1,
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        -- TODO: show source
        formatting = {
          format = require("lspkind").cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
            menu = {},
          }),
        },
      }
    end,
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
          rust_analyzer = {},
          tsserver = {
            flags = { debounce_text_changes = 500 },
            settings = { completions = { completeFunctionCalls = true } },
            -- Speed up tsserver by requiring the root directory to be a git repo
            root_dir = require("lspconfig.util").root_pattern(".git"),
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

          nil_ls = {},

          -- TODO: Set up snippet capabilities for html, json and css lsps
          html = {},
          cssls = {
            settings = {
              css = {
                validate = true,
                lint = { unknownAtRules = "ignore" },
              },
            },
          },
          gopls = {},
          taplo = {},
          eslint = {},
          zls = {},

          tsp_server = {},
        },
        setup = {
          tsserver = function(_, opts)
            require("util").lsp.on_attach(function(client, buffer)
              if client.name == "tsserver" then
                vim.keymap.set(
                  "n",
                  "<leader>ro",
                  "<cmd>TypescriptOrganizeImports<cr>",
                  { buffer = buffer, desc = "Organize Imports" }
                )
                vim.keymap.set(
                  "n",
                  "<leader>rR",
                  "<cmd>TypescriptRenameFile<cr>",
                  { buffer = buffer, desc = "Rename File" }
                )
              end
            end)

            require("typescript").setup({ server = opts })
            return true
          end,
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
        map("n", "<leader>c", function() vim.diagnostic.jump({ float = true, count = 1 }) end, { desc = "Next Diagnostic" })
        map("n", "<leader>v", function() vim.diagnostic.jump({ float = true, count = -1 }) end, { desc = "Previous Diagnostic" })
        map("n", "]d", function() vim.diagnostic.jump({ float = true, count = 1 }) end, { desc = "Next Diagnostic" })
        map("n", "[d", function() vim.diagnostic.jump({ float = true, count = -1 }) end, { desc = "Previous Diagnostic" })
        map("n", "]e", function() vim.diagnostic.jump({ float = true, severity = 1, count = 1 }) end, { desc = "Next Diagnostic" })
        map("n", "[e", function() vim.diagnostic.jump({ float = true, severity = 1, count = -1 }) end, { desc = "Previous Diagnostic" })
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

      local servers = opts.servers
      local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities() or {}
      )

      local function setup(server)
        local server_opts = vim.tbl_deep_extend("force", {
          capabilities = vim.deepcopy(capabilities),
        }, servers[server] or {})

        if opts.setup[server] then
          if opts.setup[server](server, server_opts) then
            return
          end
        elseif opts.setup["*"] then
          if opts.setup["*"](server, server_opts) then
            return
          end
        end

        lspconfig[server].setup(server_opts)
      end

      for server in pairs(servers) do
        setup(server)
      end
    end,
  },

  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = {
        auto_trigger = true,
        keymap = {
          accept = "<c-j>",
          next = "<c-l>",
          prev = "<c-h>",
          dismiss = "<c-u>",
        },
      },
    },
  },

  {
    "stevearc/conform.nvim",
    lazy = true,
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format({ timeout_ms = 3000 })
        end,
        mode = { "n", "v" },
        desc = "Format current buffer",
      },
    },
    ---@module "conform"
    ---@type conform.setupOpts
    opts = {
      default_format_opts = {
        timeout_ms = 3000,
        async = false, -- not recommended to change
        quiet = false, -- not recommended to change
        lsp_format = "fallback", -- not recommended to change
      },
      formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt" },
        html = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        graphql = { "prettier" },
        javascript = { "prettier", "eslint_d" },
        javascriptreact = { "prettier", "eslint_d" },
        typescript = { "prettier", "eslint_d" },
        typescriptreact = { "prettier", "eslint_d" },
        go = { "goimports" },
      },
      formatters = {
        injected = { options = { ignore_errors = true } },
      },
    },
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
    init = function()
      vim.api.nvim_create_autocmd("BufRead", {
        group = vim.api.nvim_create_augroup("CmpSourceCargo", { clear = true }),
        pattern = "Cargo.toml",
        callback = function()
          require("cmp").setup.buffer({ sources = { { name = "crates" } } })
          require("crates")
        end,
      })
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = "VeryLazy",
    opts = {
      -- Event to trigger linters
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        rust = { "clippy" },
      },
      ---@type table<string,table>
      linters = {},
    },
    config = function(_, opts)
      local M = {}

      local lint = require("lint")
      for name, linter in pairs(opts.linters) do
        if type(linter) == "table" and type(lint.linters[name]) == "table" then
          ---@diagnostic disable-next-line: param-type-mismatch
          lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
          if type(linter.prepend_args) == "table" then
            lint.linters[name].args = lint.linters[name].args or {}
            vim.list_extend(lint.linters[name].args, linter.prepend_args)
          end
        else
          lint.linters[name] = linter
        end
      end
      lint.linters_by_ft = opts.linters_by_ft

      function M.debounce(ms, fn)
        ---@diagnostic disable-next-line: undefined-field
        local timer = vim.uv.new_timer()
        return function(...)
          local argv = { ... }
          timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
          end)
        end
      end

      function M.lint()
        -- Use nvim-lint's logic first:
        -- * checks if linters exist for the full filetype first
        -- * otherwise will split filetype by "." and add all those linters
        -- * this differs from conform.nvim which only uses the first filetype that has a formatter
        local names = lint._resolve_linter_by_ft(vim.bo.filetype)

        -- Create a copy of the names table to avoid modifying the original.
        names = vim.list_extend({}, names)

        -- Add fallback linters.
        if #names == 0 then
          vim.list_extend(names, lint.linters_by_ft["_"] or {})
        end

        -- Add global linters.
        vim.list_extend(names, lint.linters_by_ft["*"] or {})

        -- Filter out linters that don't exist or don't match the condition.
        local ctx = { filename = vim.api.nvim_buf_get_name(0) }
        ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
        names = vim.tbl_filter(function(name)
          local linter = lint.linters[name]
          if not linter then
            print("  Linter not found: " .. name)
          end

          ---@diagnostic disable-next-line: undefined-field
          return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
        end, names)

        -- Run linters.
        if #names > 0 then
          lint.try_lint(names)
        end
      end

      vim.api.nvim_create_autocmd(opts.events, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = M.debounce(100, M.lint),
      })
    end,
  },
}
