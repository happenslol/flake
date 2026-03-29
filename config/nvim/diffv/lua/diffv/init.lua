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

--- Open a diff view.
--- Supports: :DiffV (working tree), :DiffV --cached (staged), :DiffV <commit>
---@param args? string[] command arguments
function M.open(args)
  args = args or {}

  local git = require("diffv.git")
  local provider = require("diffv.git.provider")
  local diff_engine = require("diffv.diff")
  local ui = require("diffv.ui")
  local config = require("diffv.config").values

  local root = git.repo_root()
  if not root then
    vim.notify("diffv: not in a git repository", vim.log.levels.ERROR)
    return
  end

  -- Get the list of changed files
  local files, err = provider.changed_files_sync(args)
  if err or #files == 0 then
    vim.notify("diffv: no changes found", vim.log.levels.INFO)
    return
  end

  -- For now, open the first changed file
  -- (multi-file navigation comes in a later phase)
  local file = files[1]
  local rel_path = file.path
  local abs_path = root .. "/" .. rel_path

  -- Determine filetype from the file extension
  local filetype = vim.filetype.match({ filename = rel_path }) or ""

  -- Determine which revisions to diff
  local is_cached = vim.tbl_contains(args, "--cached")
  local has_rev = false
  for _, a in ipairs(args) do
    if not a:match("^%-") then
      has_rev = true
      break
    end
  end

  local old_text, new_text

  if is_cached then
    -- Staged changes: HEAD vs index
    old_text = provider.get_file_sync("HEAD", rel_path)
    new_text = provider.get_file_sync(":", rel_path)
  elseif has_rev then
    -- Commit or range: parse the first non-flag arg
    local rev
    for _, a in ipairs(args) do
      if not a:match("^%-") then
        rev = a
        break
      end
    end

    if rev and rev:match("%.%.") then
      -- Range: a..b
      local rev_a, rev_b = rev:match("^(.+)%.%.(.+)$")
      old_text = provider.get_file_sync(rev_a, rel_path)
      new_text = provider.get_file_sync(rev_b, rel_path)
    elseif rev then
      -- Single commit: compare commit~ vs commit
      old_text = provider.get_file_sync(rev .. "~", rel_path)
      new_text = provider.get_file_sync(rev, rel_path)
    end
  else
    -- Working tree changes: HEAD vs working copy
    old_text = provider.get_file_sync("HEAD", rel_path)
    new_text = provider.get_working_copy(abs_path)
  end

  old_text = old_text or ""
  new_text = new_text or ""

  if old_text == new_text then
    vim.notify("diffv: no differences in " .. rel_path, vim.log.levels.INFO)
    return
  end

  -- Compute diff
  local diff_result = diff_engine.diff(old_text, new_text)

  -- Render
  ui.create(diff_result, filetype, config)
end

--- Close the active diff view
function M.close()
  require("diffv.ui").destroy()
end

--- Reload all diffv modules (clear from package.loaded and re-setup)
function M.reload()
  local config = require("diffv.config")
  local opts = config.values

  -- Close any active view before reloading
  pcall(function()
    local ui = require("diffv.ui")
    if ui.active then
      ui.destroy()
    end
  end)

  for name, _ in pairs(package.loaded) do
    if name:match("^diffv") then
      package.loaded[name] = nil
    end
  end

  require("diffv").setup(opts)
  vim.notify("diffv reloaded", vim.log.levels.INFO)
end

return M
