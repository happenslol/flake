local map = vim.keymap.set

map({ "n", "v" }, ";", ":")
map({ "n", "v" }, "'", '"')

-- Better up/down
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Resize window using <ctrl> arrow keys
map("n", "<c-up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<c-down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<c-left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<c-right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move Lines
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move down", silent = true })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move up", silent = true })

-- Clear search
map("n", "<leader>h", "<cmd>nohl<cr>", { silent = true, desc = "Clear Highlights" })

-- quickfix bindings
map("n", "<leader>qk", ":copen<cr>", { silent = true, desc = "Open Quickfix List" })
map("n", "<leader>qj", ":cclose<cr>", { silent = true, desc = "Close Quickfix List" })
map("n", "<leader>ql", ":cnext<cr>", { silent = true, desc = "Next Quickfix Item" })
map("n", "<leader>qh", ":cprev<cr>", { silent = true, desc = "Previous Quickfix Item" })

-- loclist bindings
map("n", "<leader>ek", ":lopen<cr>", { silent = true, desc = "Open Location List" })
map("n", "<leader>ej", ":lclose<cr>", { silent = true, desc = "Close Location List" })
map("n", "<leader>el", ":lnext<cr>", { silent = true, desc = "Next Location Item" })
map("n", "<leader>eh", ":lprev<cr>", { silent = true, desc = "Previous Location Item" })

-- quicksave
map("n", "<leader>w", ":w<cr>", { silent = true, desc = "Quicksave" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- lazy
map("n", "<leader>ll", "<cmd>:Lazy<cr>", { desc = "Lazy" })

-- Scroll active buffer using scrollwheel
map("n", "<ScrollWheelUp>", "3<c-y>", { silent = true })
map("n", "<ScrollWheelDown>", "3<c-e>", { silent = true })

-- Select next/previous line using scrollwheel in visual mode
map("v", "<ScrollWheelUp>", "k", { silent = true })
map("v", "<ScrollWheelDown>", "j", { silent = true })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Delete default diagnostic keymaps
vim.keymap.del("n", "<c-w>d")
vim.keymap.del("n", "<c-w><c-d>")
