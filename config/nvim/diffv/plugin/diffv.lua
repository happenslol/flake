if vim.g.loaded_diffv then
  return
end
vim.g.loaded_diffv = true

vim.api.nvim_create_user_command("DiffV", function(opts)
  require("diffv").open(opts.fargs)
end, {
  nargs = "*",
  desc = "Open diffv viewer",
})

vim.api.nvim_create_user_command("DiffVClose", function()
  require("diffv").close()
end, {
  desc = "Close diffv viewer",
})
