return {
  "b0o/SchemaStore.nvim",

  -- TODO
  -- snippets

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
      return {
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        snippet = {
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<S-CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
        formatting = {
          -- format = function(_, item)
          --   local icons = require("lazyvim.config").icons.kinds
          --   if icons[item.kind] then
          --     item.kind = icons[item.kind] .. item.kind
          --   end
          --   return item
          -- end,
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
      "hrsh7th/cmp-nvim-lsp",
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
      -- options for vim.diagnostic.config()
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = { spacing = 4, prefix = "●" },
        severity_sort = true,
      },
      -- options for vim.lsp.buf.format
      -- `bufnr` and `filter` is handled by the LazyVim formatter,
      -- but can be also overridden when specified
      -- TODO
      format = {
        formatting_options = nil,
        timeout_ms = nil,
      },
      -- TODO
      -- Setup json lazy schema store
      -- Setup typescript using typescript.nvim
      servers = {
        rust_analyzer = {},
        jsonls = {},
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              completion = { callSnippet = "Replace" },
            },
          },
        },
      },
      setup = {},
    },
    config = function(_, opts)
      -- setup formatting and keymaps
      -- require("lazyvim.util").on_attach(function(client, buffer)
      --   require("lazyvim.plugins.lsp.format").on_attach(client, buffer)
      --   require("lazyvim.plugins.lsp.keymaps").on_attach(client, buffer)
      -- end)

      -- diagnostics
      -- for name, icon in pairs(require("lazyvim.config").icons.diagnostics) do
      --   name = "DiagnosticSign" .. name
      --   vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
      -- end
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

  {
    "jose-elias-alvarez/null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = function()
      local null = require("null-ls")
      return {
        root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git"),
        sources = {
          null.builtins.formatting.prettierd,
          null.builtins.diagnostics.eslint_d,
          null.builtins.code_actions.eslint_d,

          null.builtins.formatting.goimports,
        },
      }
    end,
  },

  { "onsails/lspkind.nvim" }
}
