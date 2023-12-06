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
      { "folke/neodev.nvim", opts = { experimental = { pathStrict = true } } },
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
            flags = { debounce_text_changes = 500 },
            settings = {
              Lua = {
                workspace = { checkThirdParty = false },
                completion = { callSnippet = "Replace" },
              },
            },
          },

          nil_ls = {},

          -- Disable if relay config is found, see
          -- https://github.com/neovim/nvim-lspconfig/blob/master/lua/lspconfig/util.lua#L443
          -- graphql = {
          --   root_dir = require("lspconfig.util").root_pattern("src", "node_modules"),
          -- },

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
          zls = {},
        },
        setup = {
          tsserver = function(_, opts)
            require("util").on_lsp_attach(function(client, buffer)
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

      util.hook(vim.lsp.handlers, "textDocument/publishDiagnostics", function(prev, _, result, ctx, config)
        result.diagnostics = require("util").filter_diagnostics(result.diagnostics)
        return prev(nil, result, ctx, config)
      end)

      -- util.hook(vim.lsp, "buf_request_all", function(prev, bufnr, method, params, callback)
      --   return prev(bufnr, method, params, function(lsp_results)
      --     if method == "textDocument/codeAction" then
      --       return callback(require("util").sort_code_actions(lsp_results))
      --     end
      --
      --     return callback(lsp_results)
      --   end)
      -- end)

      local icons = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      for name, icon in pairs(icons) do
        name = "DiagnosticSign" .. name
        vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
      end

      local enable_lsp_formatters = {
        ["null-ls"] = true,
        ["rust_analyzer"] = true,
        ["zls"] = true,
      }

      local format = function(buf)
        vim.lsp.buf.format({
          bufnr = buf,
          filter = function(client)
            return enable_lsp_formatters[client.name] == true
          end,
        })
      end

      util.on_lsp_attach(function(client, buffer)
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

        map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
        map("n", "<leader>c", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })
        map("n", "<leader>v", vim.diagnostic.goto_prev, { desc = "Previous Diagnostic" })
        map("n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration" })
        map("n", "gI", "<cmd>Telescope lsp_implementations<cr>", { desc = "Goto Implementation" })
        map("n", "gt", "<cmd>Telescope lsp_type_definitions<cr>", { desc = "Goto Type" })
        map("n", "gr", "<cmd>Telescope lsp_references<cr>", { desc = "Show References" })

        if client.server_capabilities["signatureHelpProvider"] then
          map("n", "gK", vim.lsp.buf.signature_help, { desc = "Signature Help" })
          map("i", "<c-k>", vim.lsp.buf.signature_help, { desc = "Signature Help" })
        end

        if client.server_capabilities["codeActionProvider"] then
          map({ "n", "v" }, "<leader>a", vim.lsp.buf.code_action, { desc = "Code Actions" })
        end

        if client.server_capabilities["documentFormattingProvider"] then
          map("n", "<leader>f", function()
            format(buffer)
          end, { desc = "Format Document" })
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
      local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

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

        require("lspconfig")[server].setup(server_opts)
      end

      for server in pairs(servers) do
        setup(server)
      end
    end,
  },

  {
    "jose-elias-alvarez/null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = function()
      local null = require("null-ls")
      local eslint_patterns = { ".eslintrc.js", ".eslintrc.json", ".eslintrc" }

      return {
        root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git"),
        sources = {
          -- TODO: Why does prettierd not find the config anymore?
          null.builtins.formatting.prettier,
          null.builtins.code_actions.eslint_d.with({
            -- condition = function(utils)
            --   return utils.root_has_file(eslint_patterns)
            -- end,
          }),
          null.builtins.diagnostics.eslint_d.with({
            filter = require("util").filter_eslintd_diagnostics,
            -- condition = function(utils)
            --   return utils.root_has_file(eslint_patterns)
            -- end,
          }),

          null.builtins.formatting.shfmt,
          null.builtins.diagnostics.shellcheck,
          null.builtins.code_actions.shellcheck,
          null.builtins.formatting.stylua,
          null.builtins.formatting.alejandra,
          null.builtins.formatting.goimports,
          null.builtins.formatting.clang_format,
          null.builtins.formatting.taplo,
          null.builtins.formatting.terraform_fmt,

          require("typescript.extensions.null-ls.code-actions"),
        },
      }
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
}
