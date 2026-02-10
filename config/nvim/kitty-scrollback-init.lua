-- Used as a minimal configuration for kitty-scrollback.nvim

vim.opt.runtimepath:append(vim.fn.stdpath("config"))
require("config.options")
require("config.keymaps")

local lazy_path = vim.fn.stdpath("data") .. "/lazy"

vim.opt.runtimepath:append(lazy_path .. "/materialnight.nvim")
vim.cmd.colorscheme("materialnight")

vim.opt.runtimepath:append(lazy_path .. "/kitty-scrollback.nvim")
require("kitty-scrollback").setup({
  {
    keymaps_enabled = false,
    status_window = { autoclose = true },
    paste_window = { hide_footer = true, yank_register = "y" },
    scrollback_buffer_cols = 600,
  },
})

-- Allow quitting with q or <esc>
vim.keymap.set("n", "q", "<cmd>qa!<cr>", { silent = true })
vim.keymap.set("n", "<esc>", "<cmd>qa!<cr>", { silent = true })

-- Abort selection using q
vim.keymap.set("v", "q", "<esc>", { silent = true })

-- Allow yanking and closing with y
vim.keymap.set("v", "y", "y<cmd>qa!<cr>", { silent = true, noremap = true })
