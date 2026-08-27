-- Formatting strategy for web projects, resolved per project root. The first
-- match wins, so oxfmt/oxlint take precedence over deno, which takes precedence
-- over biome, which takes precedence over prettier/eslint:
--
--   .oxfmtrc.json   -> format with oxfmt   (disables prettier + biome + deno fmt)
--   .oxlintrc.json  -> fix with `oxlint --fix-dangerously` (disables eslint + biome + deno lint)
--   deno.json       -> deno fmt + the deno LSP's linter (disables prettier + biome)
--   biome.json      -> biome check, i.e. format + fix (disables prettier, keeps eslint)
--   .prettierrc /
--   .eslintrc       -> prettier + eslint --fix
--   (nothing)       -> biome check (format + fix)
--
-- Formatting (oxfmt/deno/biome/prettier) and fixing (oxlint/deno/biome/eslint)
-- are two separate axes, so combinations like oxfmt + oxlint or biome + eslint
-- work. Note that oxfmt and oxlint each disable deno on *both* axes, since a
-- project that opts into either has opted out of the deno toolchain.
--
-- In an oxlint project <leader>f runs three ordered steps:
--
--   1. TypeScript's `source.removeUnusedImports` code action, which is
--      authoritative for imports even where oxlint's no-unused-vars is off
--   2. `oxlint --fix-dangerously`, the only invocation that applies every fix
--      oxlint has (see the `oxlint_fix` notes below)
--   3. the formatter (oxfmt), last, so it has the final say over the output
--
-- Steps 2 and 3 are conform formatters, so conform runs them in list order;
-- step 1 is an LSP round trip that has to land before conform starts.

-- Marker detection is shared with the denols LSP config.
local webtools = require("util.webtools")
local detect, any_config = webtools.detect, webtools.any_config

-- The deno toolchain only owns a project when no ox tool has taken over.
local function deno_owns(dir)
  return detect("deno", dir) and not webtools.ox_overrides_deno(dir)
end

-- LSP clients conform is allowed to format with (eslint applies its --fix-all
-- through textDocument/formatting here). oxlint is deliberately absent: the oxc
-- language server advertises documentFormattingProvider = false, so conform can
-- never reach it, and its batch fix-all code action covers only a subset of what
-- the CLI fixes. oxlint fixes run as the `oxlint_fix` formatter instead.
local enabled_lsp_formatters = {
  "eslint",
  "rust-analyzer",
  "taplo",
  "tsp_server",
  "zls",
}

-- Ask every attached server for a whole-file `kind` source action and apply what
-- comes back. Synchronous so the edit lands before the fixers and formatters
-- run; a short timeout keeps a cold server from freezing the keypress, and
-- oxlint's fix pass removes unused imports too, so giving up here is cheap.
local function apply_source_action(buf, kind, timeout)
  local last_line = vim.api.nvim_buf_line_count(buf)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = buf, method = "textDocument/codeAction" })) do
    local params = vim.lsp.util.make_given_range_params({ 1, 0 }, { last_line, 0 }, buf, client.offset_encoding)
    params.context = { only = { kind }, diagnostics = {} }

    local res = client:request_sync("textDocument/codeAction", params, timeout, buf)
    for _, action in ipairs((res and not res.err and res.result) or {}) do
      -- most servers hand out the edit only once the action is resolved
      if not action.edit and action.data ~= nil then
        local resolved = client:request_sync("codeAction/resolve", action, timeout, buf)
        action = (resolved and not resolved.err and resolved.result) or action
      end
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
      end
      if action.command then
        local command = type(action.command) == "table" and action.command or action
        client:request_sync("workspace/executeCommand", command, timeout, buf)
      end
    end
  end
end

return {
  "stevearc/conform.nvim",
  lazy = true,
  cmd = "ConformInfo",
  keys = {
    {
      "<leader>f",
      function()
        local buf = vim.api.nvim_get_current_buf()
        local name = vim.api.nvim_buf_get_name(buf)
        local dir = name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()

        -- Step 1 of the oxlint pipeline. Skipped for a visual selection, where
        -- a file-wide import rewrite would reach well outside the range.
        if detect("oxlint", dir) and not vim.tbl_contains({ "v", "V" }, vim.fn.mode()) then
          apply_source_action(buf, "source.removeUnusedImports", 500)
        end

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
    -- Filetypes `deno fmt` handles without --unstable-component.
    local deno_fts = {
      "css",
      "html",
      "javascript",
      "javascriptreact",
      "json",
      "jsonc",
      "less",
      "markdown",
      "sass",
      "scss",
      "typescript",
      "typescriptreact",
      "yaml",
    }

    local formatters_by_ft = {
      lua = { "stylua" },
      sh = { "shfmt" },
      go = { "goimports", "gofumpt" },
      nix = { "alejandra" },
      kdl = { "kdlfmt" },
      terraform = { "terraform_fmt" },
      ["terraform-vars"] = { "terraform_fmt" },
    }

    local function add(fts, formatter)
      for _, ft in ipairs(fts) do
        formatters_by_ft[ft] = formatters_by_ft[ft] or {}
        table.insert(formatters_by_ft[ft], formatter)
      end
    end

    -- Order matters: fix first, then format, so the formatter has the final say.
    -- (eslint fixes are applied by its LSP server via lsp_format above.)
    add(deno_fts, "deno_fmt")
    add(ox_fts, "oxlint_fix")
    add(ox_fts, "oxfmt")
    add(biome_fts, "biome")
    add(prettier_fts, "prettierd")

    ---@type conform.setupOpts
    return {
      formatters_by_ft = formatters_by_ft,
      formatters = {
        -- `--fix-dangerously` is the only invocation that applies everything:
        -- `--fix` alone covers neither unused imports nor `==` -> `===`, and
        -- passing it alongside the others silently fixes nothing at all. The
        -- flip side is that unused *variables* get deleted too, which is what
        -- "fix all" means here; `--fix-suggestions` instead limits the pass to
        -- unused imports. oxlint exits 1 when unfixable errors remain.
        oxlint_fix = {
          command = require("conform.util").from_node_modules("oxlint"),
          args = { "--fix-dangerously", "$FILENAME" },
          stdin = false,
          exit_codes = { 0, 1 },
          cwd = function(_, ctx)
            return webtools.root("oxlint", ctx.dirname)
          end,
          condition = function(_, ctx)
            return detect("oxlint", ctx.dirname)
          end,
        },
        deno_fmt = {
          condition = function(_, ctx)
            return deno_owns(ctx.dirname)
          end,
        },
        oxfmt = {
          condition = function(_, ctx)
            return detect("oxfmt", ctx.dirname)
          end,
        },
        biome = {
          -- `check` runs the formatter + lint fixes; assist (import sorting) stays off.
          args = { "check", "--write", "--assist-enabled=false", "--stdin-file-path", "$FILENAME" },
          condition = function(_, ctx)
            -- deno/oxfmt/oxlint take over biome's job entirely when configured.
            if detect("oxfmt", ctx.dirname) or detect("oxlint", ctx.dirname) or detect("deno", ctx.dirname) then
              return false
            end
            -- Explicit biome project, or the fallback when nothing else is configured.
            return detect("biome", ctx.dirname) or not any_config(ctx.dirname)
          end,
        },
        prettierd = {
          condition = function(_, ctx)
            local ft = vim.bo[ctx.buf].filetype

            -- deno fmt owns every filetype it supports, including the ones
            -- biome can't handle (markdown, yaml, html, ...).
            if deno_owns(ctx.dirname) then
              return false
            end

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
