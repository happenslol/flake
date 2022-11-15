local null = require "null-ls"

null.setup {
  sources = {
    null.builtins.formatting.prettier_d_slim,
    null.builtins.formatting.eslint_d,
  }
}
