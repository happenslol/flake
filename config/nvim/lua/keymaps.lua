local util = require "util"
local cmp = require "cmp"

local map = util.create_keymap()

-- Shortcuts for native vim commands
map.n[";"] = { ":", silent = false }
map.v[";"] = { ":", silent = false }
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

-- Configure lsp keymap
local lsp_map = util.create_keymap()

lsp_map.n["K"] = vim.lsp.buf.hover
lsp_map.i["<ctrl>k"] = vim.lsp.buf.signature_help
lsp_map.n["gd"] = vim.lsp.buf.definition
lsp_map.n["gD"] = vim.lsp.buf.declaration
lsp_map.n["<space>i"] = vim.lsp.buf.implementation
lsp_map.n["<space>r"] = vim.lsp.buf.references

lsp_map.n["<space>a"] = vim.lsp.buf.code_action
lsp_map.n["<space>r"] = vim.lsp.buf.rename
lsp_map.n["<leader>f"] = vim.lsp.buf.format

lsp_map.n["<space>c"] = vim.diagnostic.goto_next
lsp_map.n["<space>v"] = vim.diagnostic.goto_prev

-- Configure cmp mappings
local cmp_map = {}

local cmp_select_next = function(fallback)
  if cmp.visible() then
    cmp.select_next_item()
  else
    fallback()
  end
end

local cmp_select_prev = function(fallback)
  if cmp.visible() then
    cmp.select_prev_item()
  else
    fallback()
  end
end

cmp_map["<tab>"] = cmp_select_next
cmp_map["<down>"] = cmp_select_next
cmp_map["<s-tab>"] = cmp_select_prev
cmp_map["<up>"] = cmp_select_prev

cmp_map["<c-space>"] = cmp.mapping.complete()
cmp_map["<c-e>"] = cmp.mapping.close()
cmp_map["<cr>"] = cmp.mapping.confirm {
  behavior = cmp.ConfirmBehavior.Replace,
  select = false,
}

-- Configure bqf mappings
local bqf_map = {
  pscrollup = "",
  pscrolldown = "",
}

return {
  global_keymap = map,
  bqf_keymap = bqf_map,
  lsp_keymap = lsp_map,
  cmp_keymap = cmp_map,
}
