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

vim.api.nvim_create_user_command("DiffVLog", function()
  require("diffv.picker").log()
end, {
  desc = "Browse git log and open commits in diffv",
})

vim.api.nvim_create_user_command("DiffVCommit", function(opts)
  local rev = opts.fargs[1]
  if not rev then
    vim.notify("Usage: DiffVCommit <revision>", vim.log.levels.ERROR)
    return
  end
  require("diffv").open_commit(rev)
end, {
  nargs = 1,
  desc = "Open a commit in diffv with file list",
})

vim.api.nvim_create_user_command("DiffVClose", function()
  require("diffv").close()
end, {
  desc = "Close diffv viewer",
})
