--- Remote review integration (GitHub, GitLab).
--- Pushes review comments to merge/pull request APIs.
local M = {}

--- Detect the remote provider (github, gitlab) from git remotes.
---@param cwd? string
---@return "github" | "gitlab" | nil provider
function M.detect_provider(cwd)
  vim.notify("diffv: review.remote.detect_provider() not yet implemented", vim.log.levels.INFO)
  return nil
end

--- Push review comments to the remote provider.
---@param comments diffv.Comment[]
---@param opts { provider: "github" | "gitlab", mr_id: number }
function M.push_comments(comments, opts)
  vim.notify("diffv: review.remote.push_comments() not yet implemented", vim.log.levels.INFO)
end

--- Fetch an MR/PR for local review.
---@param id number merge/pull request ID
---@param opts? { provider?: "github" | "gitlab" }
function M.fetch_mr(id, opts)
  vim.notify("diffv: review.remote.fetch_mr() not yet implemented", vim.log.levels.INFO)
end

return M
