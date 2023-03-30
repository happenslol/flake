-- TODO: Adapt keymaps from lazyvim
-- Add old keymaps
local map = vim.keymap.set

map({ "n", "v" }, ";", ":", { silent = false })
