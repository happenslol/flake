---@param ctx ConformCtx
local function has_prettier_config(ctx)
  vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
  return vim.v.shell_error == 0
end

local enabled_lsp_formatters = {
  "eslint",
  "rust-analyzer",
}

return {
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
            return vim.tbl_contains(enabled_lsp_formatters, client.name)
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
      formatters_by_ft = formatters_by_ft,
      formatters = {
        -- Only use biome if there's no prettier config
        biome = {
          condition = cached("biome", function(_, ctx)
            return not has_prettier_config(ctx)
          end),
        },
        prettierd = {
          condition = cached("prettierd", function(_, ctx)
            -- If we don't have biome, always use prettier
            if not vim.tbl_contains(biome_fts, vim.bo.filetype) then
              return true
            end

            -- If we have biome and no specific prettier config, use biome
            return has_prettier_config(ctx)
          end),
        },
        injected = { options = { ignore_errors = true } },
      },
    }
  end,
}
