local null = require "null-ls"

null.setup {
  sources = {
    null.builtins.formatting.prettierd,
    null.builtins.diagnostics.eslint_d,
    null.builtins.code_actions.eslint_d,
  }
}
