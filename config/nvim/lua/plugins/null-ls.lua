local null = require "null-ls"

null.setup {
  sources = {
    null.builtins.formatting.prettier,
    null.builtins.diagnostics.eslint_d,
    null.builtins.code_actions.eslint_d,
  }
}
