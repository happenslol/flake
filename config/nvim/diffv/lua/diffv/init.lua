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
  require("diffv.colors").setup()
  require("diffv.config").setup(opts)
end

--- Open a diff view.
--- Supports: :DiffV (working tree), :DiffV --cached (staged), :DiffV <commit>, :DiffV a..b
---@param args? string[] command arguments
---@param file_path? string specific file to diff (relative to repo root)
function M.open(args, file_path)
  args = args or {}
  local state_mod = require("diffv.state")
  local state = state_mod.create(args, { file_path = file_path })
  if state then
    state:open()
  end
end

--- Open a commit with the file list panel.
---@param rev string commit hash
function M.open_commit(rev)
  M.open({ rev })
end

--- Open an inline diff view (convenience wrapper).
---@param args? string[]
---@param file_path? string
function M.open_inline(args, file_path)
  args = args or {}
  local state_mod = require("diffv.state")
  local state = state_mod.create(args, { file_path = file_path, layout = "inline" })
  if state then
    state:open()
  end
end

--- Built-in actions, usable as function values in keymap config.
M.actions = require("diffv.actions")

--- Close the active diff view
function M.close()
  local state_mod = require("diffv.state")
  if state_mod.active then
    state_mod.active:destroy()
  end
end

--- Reload all diffv modules (clear from package.loaded and re-setup)
function M.reload()
  local config = require("diffv.config")
  local opts = config.values

  pcall(M.close)

  for name, _ in pairs(package.loaded) do
    if name:match("^diffv") then
      package.loaded[name] = nil
    end
  end

  require("diffv").setup(opts)
  vim.notify("diffv reloaded", vim.log.levels.INFO)
end

return M
