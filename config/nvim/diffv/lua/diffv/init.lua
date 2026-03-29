local M = {}

local ns = vim.api.nvim_create_namespace("diffv")

--- Get the diffv namespace id
---@return number
function M.ns()
  return ns
end

--- Setup diffv with user options
---@param opts? table
function M.setup(opts)
  require("diffv.config").setup(opts)
end

--- Open a diff view
---@param args? string[] command arguments (commit, range, flags)
function M.open(args)
  vim.notify("diffv: open() not yet implemented", vim.log.levels.INFO)
end

--- Close the active diff view
function M.close()
  vim.notify("diffv: close() not yet implemented", vim.log.levels.INFO)
end

--- Reload all diffv modules (clear from package.loaded and re-setup)
function M.reload()
  local config = require("diffv.config")
  local opts = config.values

  for name, _ in pairs(package.loaded) do
    if name:match("^diffv") then
      package.loaded[name] = nil
    end
  end

  require("diffv").setup(opts)
  vim.notify("diffv reloaded", vim.log.levels.INFO)
end

return M
