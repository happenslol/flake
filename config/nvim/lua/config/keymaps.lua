local map = vim.keymap.set

map({ "n", "v" }, ";", ":", { silent = false })

-- Better up/down
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Resize window using <ctrl> arrow keys
map("n", "<c-up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<c-down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<c-left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<c-right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move Lines
map("v", "<c-j>", ":m '>+1<cr>gv=gv", { desc = "Move down", silent = true })
map("v", "<c-k>", ":m '<-2<cr>gv=gv", { desc = "Move up", silent = true })

-- Clear search
map("n", "<leader>h", "<cmd>nohl<cr>", { silent = true })

-- Better quickfix bindings
map("n", "<c-d>k", ":copen<cr>")
map("n", "<c-d>j", ":cclose<cr>")
map("n", "<c-d>l", ":cnext<cr>")
map("n", "<c-d>h", ":cprev<cr>")

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- lazy
map("n", "<leader>ll", "<cmd>:Lazy<cr>", { desc = "Lazy" })
