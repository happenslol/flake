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
map("n", "<leader>wk", ":lopen<cr>", { silent = true, desc = "Open Location List" })
map("n", "<leader>wj", ":lclose<cr>", { silent = true, desc = "Close Location List" })
map("n", "<leader>wl", ":lnext<cr>", { silent = true, desc = "Next Location Item" })
map("n", "<leader>wh", ":lprev<cr>", { silent = true, desc = "Previous Location Item" })

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

-- Delete default diagnostic keymaps
vim.keymap.del("n", "<c-w>d")
vim.keymap.del("n", "<c-w><c-d>")
