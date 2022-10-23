local util = require "util"
local map = util.create_keymap()

util.set_global { mapleader = "," }

-- Shortcuts for native vim commands
map.n[";"] = { ":", silent = false }
map.n["<leader>h"] = ":nohlsearch<cr>"

-- neo-tree
map.n["<c-n>"] = ":Neotree focus toggle<cr>"

-- packer
map.n["<leader>pc"] = ":PackerCompile<cr>"
map.n["<leader>ps"] = ":PackerSync<cr>"

-- wildfire
map.n["<backspace>"] = "<plug>(wildfire-fuel)"
map.v["<backspace>"] = "<plug>(wildfire-fuel)"
map.n["<c-backspace>"] = "<plug>(wildfire-water)"

-- Location list
map.n["<c-f>k"] = ":copen<cr>"
map.n["<c-f>j"] = ":cclose<cr>"
map.n["<c-f>l"] = ":cnext<cr>"
map.n["<c-f>h"] = ":cprev<cr>"

-- Location list
map.n["<c-d>k"] = ":lopen<cr>"
map.n["<c-d>j"] = ":lclose<cr>"
map.n["<c-d>l"] = ":lnext<cr>"
map.n["<c-d>h"] = ":lprev<cr>"

-- telescope
map.n["<c-p>"] = ":Telescope find_files<cr>"
map.n["<leader>q"] = ":Telescope live_grep<cr>"

-- ArgWrap
map.n["<leader>w"] = ":ArgWrap<cr>"

util.apply_keymap(map)
