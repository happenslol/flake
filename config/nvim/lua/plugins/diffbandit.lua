-- DiffBandit finds the repo from the current buffer's name, which breaks when
-- that buffer is a `gitsigns://` diff (or any other URI-named buffer), so use
-- the cwd as the root for those.
local function run(fn, opts)
  return function()
    local call_opts = vim.tbl_extend("force", { pathspecs = {} }, opts or {})
    if vim.api.nvim_buf_get_name(0):match("^%a[%w+.-]*://") then
      call_opts.root = vim.uv.cwd()
    end

    local ok, err = require("diffbandit")[fn](call_opts)
    if not ok and err then
      vim.notify(tostring(err), vim.log.levels.ERROR, { title = "DiffBandit" })
    end
  end
end

---@type LazySpec
return {
  "CoreyKaylor/diffbandit.nvim",
  cmd = {
    "DiffBandit",
    "DiffBanditBuffers",
    "DiffBanditFolderDiff",
    "DiffBanditGit",
    "DiffBanditGitCurrent",
    "DiffBanditCommitPanel",
    "DiffBanditGitMenu",
    "DiffBanditGitLog",
    "DiffBanditGitCommit",
    "DiffBanditGitCompare",
    "DiffBanditGitCheckout",
    "DiffBanditMerge",
  },
  keys = {
    { "<leader>gv", run("git"), desc = "Review changes" },
    { "<leader>gV", run("git", { mode = "staged" }), desc = "Review staged changes" },
    { "<leader>gf", "<cmd>DiffBanditGitCurrent<cr>", desc = "Diff current file" },
    { "<leader>gL", run("git_log"), desc = "Git log" },
    { "<leader>gm", run("git_menu"), desc = "Git menu" },
    { "<leader>gC", run("commit_panel"), desc = "Commit panel" },
    { "<leader>go", run("git_compare_branches"), desc = "Compare branches" },
    { "<leader>gM", "<cmd>DiffBanditMerge<cr>", desc = "Resolve conflicts" },
  },
  opts = {
    ui = {
      -- herdr reports a pixel size of 0 for its ptys, so DiffBandit would guess
      -- a 1:2 cell and the connector images end up scaled and misaligned
      kitty = vim.env.HC_TERMINAL_ID and { cell_px = { 10, 29 } } or nil,
    },
  },
}
