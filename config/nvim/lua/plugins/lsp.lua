return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end,
    },
    opts = {
      history = true,
      delete_check_events = "TextChanged",
    },
    -- stylua: ignore
    keys = {
      {
        "<tab>",
        function()
          return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
        end,
        expr = true, silent = true, mode = "i",
      },
      { "<tab>", function() require("luasnip").jump(1) end, mode = "s" },
      { "<s-tab>", function() require("luasnip").jump(-1) end, mode = { "i", "s" } },
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
        if cmp.visible() then cmp.select_next_item()
        else fallback() end
      end

      local cmp_select_prev = function(fallback)
        if cmp.visible() then cmp.select_prev_item()
        else fallback() end
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
          ["<c-e>"] = cmp.mapping.abort(),
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
        formatting = {
          format = require("lspkind").cmp_format({
            mode = "symbol",
            maxwidth = 50,
            ellipsis_char = "...",
            menu = {},
          }),
        },
        experimental = {
          ghost_text = {
            hl_group = "LspCodeLens",
          },
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
      {
        "tamago324/nlsp-settings.nvim",
        opts = {
          config_home = vim.fn.stdpath "config" .. "/nlsp-settings",
          local_settings_dir = ".nlsp-settings",
          local_settings_root_markers_fallback = { ".git" },
          append_default_schemas = true,
          loader = "json",
        },
      },
    },
    opts = {
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
        },
      },
      servers = {
        -- TODO: Set up snippet capabilities for html, json and css lsps
        jsonls = {
          on_new_config = function(new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(
              new_config.settings.json.schemas,
              require("schemastore").json.schemas()
            )
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
            vim.list_extend(
              new_config.settings.yaml.schemas,
              require("schemastore").yaml.schemas()
            )
          end,
          settings = { yaml = { keyOrdering = false } },
        },
        rust_analyzer = {},
        tsserver = { settings = { completions = { completeFunctionCalls = true } } },
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              completion = { callSnippet = "Replace" },
            },
          },
        },
        nil_ls = {},
        graphql = {},
        html = {},
        cssls = {},
        gopls = {},
      },
      setup = {
        tsserver = function(_, opts)
          require("util").on_attach(function(client, buffer)
            if client.name == "tsserver" then
              -- stylua: ignore
              vim.keymap.set("n", "<leader>co",
                "<cmd>TypescriptOrganizeImports<CR>",
                { buffer = buffer, desc = "Organize Imports" })
              -- stylua: ignore
              vim.keymap.set("n", "<leader>cR",
                "<cmd>TypescriptRenameFile<CR>",
                { buffer = buffer, desc = "Rename File" })
            end
          end)

          require("typescript").setup({ server = opts })
          return true
        end,
      },
    },
    config = function(_, opts)
      local icons = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      for name, icon in pairs(icons) do
        name = "DiagnosticSign" .. name
        vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
      end

      require("util").on_attach(function(client, buffer)
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
        map("n", "<leader>v", vim.diagnostic.goto_next, { desc = "Previous Diagnostic" })
        map("n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration" })
        map("n", "gI", "<cmd>Telescope lsp_implementations", { desc = "Goto Implementation" })
        map("n", "gt", "<cmd>Telescope lsp_type_definitions", { desc = "Goto Type" })
        map("n", "gr", "<cmd>Telescope lsp_references", { desc = "Show References" })

        if client.server_capabilities["signatureHelpProvider"] then
          map("n", "gK", vim.lsp.buf.signature_help, { desc = "Signature Help" })
          map("i", "<c-k>", vim.lsp.buf.signature_help, { desc = "Signature Help" })
        end

        if client.server_capabilities["codeActionProvider"] then
          map({"n", "v"}, "<leader>a", vim.lsp.buf.code_action, { desc = "Code Actions" })
        end

        if client.server_capabilities["documentFormattingProvider"] then
          -- TODO: Prefer null-ls
          map("n", "<leader>f", vim.lsp.buf.format, { desc = "Format Document" })
        end

        if client.server_capabilities["definitionProvider"] then
          map("n", "gd", "<cmd>Telescope lsp_definitions<cr>", { desc = "Goto Definition" })
        end

        if client.server_capabilities["renameProvider"] then
          map("n", "<leader>r", vim.lsp.buf.rename, { desc = "Rename" })
        end
      end)

      vim.diagnostic.config(opts.diagnostics)

      local servers = opts.servers
      local capabilities = require("cmp_nvim_lsp")
        .default_capabilities(vim.lsp.protocol.make_client_capabilities())

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
      return {
        root_dir = require("null-ls.utils").root_pattern(
          ".null-ls-root", ".neoconf.json", "Makefile", ".git"
        ),
        sources = {
          null.builtins.formatting.prettierd,
          null.builtins.diagnostics.eslint_d,
          null.builtins.code_actions.eslint_d,

          null.builtins.formatting.shfmt,
          null.builtins.diagnostics.shellcheck,
          null.builtins.code_actions.shellcheck,

          null.builtins.diagnostics.selene,
          null.builtins.formatting.stylua,

          null.builtins.formatting.alejandra,

          null.builtins.formatting.goimports,
        },
      }
    end,
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
          require("cmp").setup.buffer { sources = { { name = "crates" } } }
          require "crates"
        end,
      })
    end,
  },
}
