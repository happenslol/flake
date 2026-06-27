-- Formatting strategy for web projects, resolved per project root:
--
--   .oxfmtrc.json   -> format with oxfmt   (disables prettier + biome)
--   .oxlintrc.json  -> fix with oxlint     (disables eslint + biome)
--   biome.json      -> biome check, i.e. format + fix (disables prettier, keeps eslint)
--   .prettierrc /
--   .eslintrc       -> prettier + eslint --fix
--   (nothing)       -> biome check (format + fix)
--
-- Formatting (oxfmt/biome/prettier) and fixing (oxlint/biome/eslint) are two
-- separate axes, so combinations like oxfmt + oxlint or biome + eslint work.

-- Marker files (and package.json keys) that identify each tool's config.
local detectors = {
  oxfmt = { files = { ".oxfmtrc.json", ".oxfmtrc.jsonc" } },
  oxlint = { files = { ".oxlintrc.json", ".oxlintrc.jsonc" } },
  biome = { files = { "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" } },
  prettier = {
    pkg_key = "prettier",
    files = {
      ".prettierrc",
      ".prettierrc.json",
      ".prettierrc.yml",
      ".prettierrc.yaml",
      ".prettierrc.json5",
      ".prettierrc.js",
      ".prettierrc.cjs",
      ".prettierrc.mjs",
      ".prettierrc.ts",
      ".prettierrc.toml",
      "prettier.config.js",
      "prettier.config.cjs",
      "prettier.config.mjs",
      "prettier.config.ts",
    },
  },
  eslint = {
    pkg_key = "eslintConfig",
    files = {
      ".eslintrc",
      ".eslintrc.js",
      ".eslintrc.cjs",
      ".eslintrc.json",
      ".eslintrc.yaml",
      ".eslintrc.yml",
      "eslint.config.js",
      "eslint.config.mjs",
      "eslint.config.cjs",
      "eslint.config.ts",
      "eslint.config.mts",
    },
  },
}

-- Whether `tool`'s config exists above `dir`, cached per (tool, dir).
local cache = {}
local function detect(tool, dir)
  dir = (dir and dir ~= "") and dir or vim.fn.getcwd()
  local key = tool .. "\0" .. dir
  if cache[key] == nil then
    local spec = detectors[tool]
    cache[key] = vim.fs.root(dir, function(name, path)
      if vim.tbl_contains(spec.files, name) then
        return true
      end
      if spec.pkg_key and name == "package.json" then
        local ok, data = pcall(function()
          return vim.json.decode(table.concat(vim.fn.readfile(vim.fs.joinpath(path, name)), "\n"))
        end)
        return (ok and type(data) == "table" and data[spec.pkg_key] ~= nil) or false
      end
      return false
    end) ~= nil
  end
  return cache[key]
end

-- True if any of the tools we care about is configured in this project.
local function any_config(dir)
  for tool in pairs(detectors) do
    if detect(tool, dir) then
      return true
    end
  end
  return false
end

-- LSP clients conform is allowed to format with (eslint applies its fixes here).
local enabled_lsp_formatters = {
  "eslint",
  "rust-analyzer",
  "taplo",
  "tsp_server",
  "zls",
}

return {
  "stevearc/conform.nvim",
  lazy = true,
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>f",
      function()
        local name = vim.api.nvim_buf_get_name(0)
        local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()

        require("conform").format({
          async = true,
          timeout_ms = 3000,
          quiet = false,

          -- Run LSP formatters (eslint fix-all) before conform's own formatters.
          lsp_format = "first",
          filter = function(client)
            if not vim.tbl_contains(enabled_lsp_formatters, client.name) then
              return false
            end
            -- oxlint replaces eslint when an oxlint config is present.
            if client.name == "eslint" and detect("oxlint", dir) then
              return false
            end
            return true
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
    -- Neovim's per-session temp dir, so conform's temp files (oxlint, see below)
    -- don't get dropped next to the files being formatted.
    local tmpdir = vim.fs.dirname(vim.fn.tempname())

    -- Filetypes each toolchain can handle.
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
      "astro",
      "css",
      "graphql",
      "javascript",
      "javascriptreact",
      "json",
      "jsonc",
      "typescript",
      "typescriptreact",
    }
    local ox_fts = {
      "javascript",
      "javascriptreact",
      "typescript",
      "typescriptreact",
    }

    local formatters_by_ft = {
      lua = { "stylua" },
      sh = { "shfmt" },
      go = { "goimports", "gofumpt" },
      nix = { "alejandra" },
      kdl = { "kdlfmt" },
    }

    local function add(fts, formatter)
      for _, ft in ipairs(fts) do
        formatters_by_ft[ft] = formatters_by_ft[ft] or {}
        table.insert(formatters_by_ft[ft], formatter)
      end
    end

    -- Order matters: fix first, then format, so the formatter has the final say.
    add(ox_fts, "oxlint")
    add(ox_fts, "oxfmt")
    add(biome_fts, "biome")
    add(prettier_fts, "prettierd")

    ---@type conform.setupOpts
    return {
      formatters_by_ft = formatters_by_ft,
      formatters = {
        oxfmt = {
          condition = function(_, ctx)
            return detect("oxfmt", ctx.dirname)
          end,
        },
        oxlint = {
          -- `oxlint --fix` writes to disk (it has no fix-to-stdout mode), so conform
          -- has to hand it a temp file. Put that temp file in the session temp dir
          -- instead of next to the source, and run from the config root so
          -- .oxlintrc.json is still discovered.
          cwd = require("conform.util").root_file({ ".oxlintrc.json", ".oxlintrc.jsonc" }),
          tmpfile_format = tmpdir .. "/conform.$RANDOM.$FILENAME",
          condition = function(_, ctx)
            return detect("oxlint", ctx.dirname)
          end,
        },
        biome = {
          -- `check` runs the formatter + lint fixes; assist (import sorting) stays off.
          args = { "check", "--write", "--assist-enabled=false", "--stdin-file-path", "$FILENAME" },
          condition = function(_, ctx)
            -- oxfmt/oxlint take over biome's job entirely when configured.
            if detect("oxfmt", ctx.dirname) or detect("oxlint", ctx.dirname) then
              return false
            end
            -- Explicit biome project, or the fallback when nothing else is configured.
            return detect("biome", ctx.dirname) or not any_config(ctx.dirname)
          end,
        },
        prettierd = {
          condition = function(_, ctx)
            local ft = vim.bo[ctx.buf].filetype

            -- oxfmt owns js/ts formatting when configured.
            if vim.tbl_contains(ox_fts, ft) and detect("oxfmt", ctx.dirname) then
              return false
            end

            -- For filetypes biome supports, biome wins unless this is a prettier/eslint project.
            if vim.tbl_contains(biome_fts, ft) then
              if detect("biome", ctx.dirname) then
                return false
              end
              return detect("prettier", ctx.dirname) or detect("eslint", ctx.dirname)
            end

            -- Filetypes biome can't handle (yaml, markdown, html, ...): prettier always.
            return true
          end,
        },
        injected = { options = { ignore_errors = true } },
      },
    }
  end,
}
