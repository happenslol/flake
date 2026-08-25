local dir = vim.fn.expand("~/code/review.nvim")

-- Only load if the plugin is checked out locally, since it's not published yet.
if not vim.uv.fs_stat(dir) then
  return {}
end

---@type LazySpec
return {
  "happenslol/review.nvim",
  dir = dir,
  cmd = "Review",
  opts = {},
}
