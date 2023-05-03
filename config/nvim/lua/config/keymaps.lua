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
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move down", silent = true })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move up", silent = true })

-- Clear search
map("n", "<leader>h", "<cmd>nohl<cr>", { silent = true })

-- quickfix bindings
map("n", "<leader>qk", ":copen<cr>", { silent = true })
map("n", "<leader>qj", ":cclose<cr>", { silent = true })
map("n", "<leader>ql", ":cnext<cr>", { silent = true })
map("n", "<leader>qh", ":cprev<cr>", { silent = true })

-- loclist bindings
map("n", "<leader>wk", ":lopen<cr>", { silent = true })
map("n", "<leader>wj", ":lclose<cr>", { silent = true })
map("n", "<leader>wl", ":lnext<cr>", { silent = true })
map("n", "<leader>wh", ":lprev<cr>", { silent = true })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- lazy
map("n", "<leader>ll", "<cmd>:Lazy<cr>", { desc = "Lazy" })
