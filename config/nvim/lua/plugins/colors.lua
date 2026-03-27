-- cozynight is loaded directly from lua/cozynight/ (no plugin needed)
require("cozynight").setup({
  plugins = { all = true },
})
vim.cmd.colorscheme("cozynight")

return {}
