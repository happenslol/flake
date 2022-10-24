local util = require "util"
local cmp = require "cmp"
local mason = require "mason"
local mason_lspconfig = require "mason-lspconfig"
local lspkind = require "lspkind"
local lspconfig = require "lspconfig"
local lspconfig_defaults = lspconfig.util.default_config

-- Avoid showing message extra message when using completion
vim.opt.shortmess:append "c"
vim.opt.completeopt = {'menu', 'menuone', 'noselect'}

-- Add cmp capabilities to default options
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
  "force",
  lspconfig_defaults.capabilities,
  require "cmp_nvim_lsp".default_capabilities()
)

vim.api.nvim_create_autocmd("LspAttach", {
  desc = "LSP commands",
  callback = function()
    util.apply_keymap(require "keymaps".lsp_keymap, { buffer = true })
  end,
})

cmp.setup {
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  sources = {
    { name = 'path' },
    { name = 'nvim_lsp', keyword_length = 3 },
    { name = 'buffer', keyword_length = 3 },
    { name = 'luasnip', keyword_length = 2 },
  },
  window = { documentation = cmp.config.window.bordered() },
  mapping = require "keymaps".cmp_keymap,
  formatting = {
    format = lspkind.cmp_format {
      mode = 'symbol',
      maxwidth = 50,
      ellipsis_char = '...',
    },
  },
}

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(
  vim.lsp.handlers.hover,
  {border = 'rounded'}
)

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(
  vim.lsp.handlers.signature_help,
  {border = 'rounded'}
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

mason.setup {
  ui = { border = "rounded" },
}

mason_lspconfig.setup {
  ensure_installed = {},
}
