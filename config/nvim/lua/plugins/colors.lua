-- materialnight is loaded directly from lua/materialnight/ (no plugin needed)
require("materialnight").setup({
  plugins = { all = true },
})
vim.cmd.colorscheme("materialnight")

return {}
