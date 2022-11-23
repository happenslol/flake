local util = require "util"
local cmp = require "cmp"
local lspkind = require "lspkind"
local luasnip = require "luasnip"
local lspconfig = require "lspconfig"
local lspconfig_defaults = lspconfig.util.default_config

-- Avoid showing message extra message when using completion
vim.opt.shortmess:append "c"
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Add cmp capabilities to default options
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
  "force",
  lspconfig_defaults.capabilities,
  require "cmp_nvim_lsp".default_capabilities()
)

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP commands",
  callback = function()
    util.apply_keymap(require "keymaps".lsp, { buffer = true })
  end,
})

cmp.setup {
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  sources = {
    { name = "path" },
    { name = "nvim_lsp", keyword_length = 1 },
    { name = "buffer", keyword_length = 3 },
    { name = "luasnip", keyword_length = 2 },
  },
  window = { documentation = cmp.config.window.bordered() },
  mapping = require "keymaps".cmp,
  formatting = {
    format = lspkind.cmp_format {
      mode = "symbol_text",
      maxwidth = 50,
      ellipsis_char = "...",
    },
  },
}

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover,
  { border = "rounded" }
)

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers.signature_help,
  { border = "rounded" }
)

vim.diagnostic.config {
  virtual_text = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
}

util.sign_define {
  { "DiagnosticSignError", "" },
  { "DiagnosticSignWarn", "" },
  { "DiagnosticSignInfo", "" },
  { "DiagnosticSignHint", "" },
}

local lsp_configs = {
  ["sumneko_lua"] = {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
        telemetry = { enable = false },
      },
    },
  },
  ["rust_analyzer"] = {},
  ["html"] = {},
  ["jsonls"] = { cmd = { "json-languageserver", "--stdio" } },
  ["tsserver"] = {
    on_attach = function(client, _)
      client.server_capabilities["documentFormattingProvider"] = false
      client.server_capabilities["documentRangeFormattingProvider"] = false
    end,
  },
}

for lsp, config in pairs(lsp_configs) do
  lspconfig[lsp].setup(config)
end
