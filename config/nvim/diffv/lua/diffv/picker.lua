--- Snacks.nvim picker for diffv.
--- Lists changed files with inline diff preview.
local M = {}

local status_labels = {
  M = "modified",
  A = "added",
  D = "deleted",
  R = "renamed",
  C = "copied",
  U = "unmerged",
}

local status_icons = {
  M = { icon = "~", hl = "DiffChange" },
  A = { icon = "+", hl = "DiffAdd" },
  D = { icon = "-", hl = "DiffDelete" },
  R = { icon = "→", hl = "DiffChange" },
}

--- Build a diff preview for a file.
---@param ctx snacks.picker.preview.ctx
local function diff_preview(ctx)
  local item = ctx.item
  if not item or not item.file then
    ctx.preview:notify("No file selected", "warn")
    return
  end

  local git = require("diffv.git")
  local provider = require("diffv.git.provider")
  local diff_engine = require("diffv.diff")

  local root = git.repo_root()
  if not root then
    return
  end

  local rel_path = item.file
  local abs_path = root .. "/" .. rel_path
  local args = item.diff_args or {}

  -- Fetch old and new content based on diff mode
  local old_text, new_text
  local is_cached = vim.tbl_contains(args, "--cached")

  if is_cached then
    old_text = provider.get_file_sync("HEAD", rel_path)
    new_text = provider.get_file_sync(":", rel_path)
  elseif item.rev then
    if item.rev:match("%.%.") then
      local rev_a, rev_b = item.rev:match("^(.+)%.%.(.+)$")
      old_text = provider.get_file_sync(rev_a, rel_path)
      new_text = provider.get_file_sync(rev_b, rel_path)
    else
      old_text = provider.get_file_sync(item.rev .. "~", rel_path)
      new_text = provider.get_file_sync(item.rev, rel_path)
    end
  else
    old_text = provider.get_file_sync("HEAD", rel_path)
    new_text = provider.get_working_copy(abs_path)
  end

  old_text = old_text or ""
  new_text = new_text or ""

  if old_text == new_text then
    ctx.preview:notify("No differences", "info")
    return
  end

  -- Compute diff and render as inline overlay
  local diff_result = diff_engine.diff(old_text, new_text)
  local inline = require("diffv.ui.inline")
  local diffv_config = require("diffv.config").values

  -- Detect filetype from the file path
  local filetype = vim.filetype.match({ filename = rel_path }) or ""

  -- Set up preview buffer with the new file content + syntax highlighting
  local buf = ctx.preview:scratch({ ft = filetype })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, diff_result.new_lines)

  -- Start treesitter on the preview buffer for syntax highlighting
  pcall(vim.treesitter.start, buf, vim.treesitter.language.get_lang(filetype) or filetype)

  -- Apply the inline overlay (deleted lines as virt_lines with syntax hl, changes highlighted)
  inline.apply_overlay(buf, diff_result, diffv_config, filetype)
end

--- Format a changed file item for display.
---@param item snacks.picker.finder.Item
---@param picker snacks.Picker
local function format_item(item, picker)
  local ret = {} ---@type snacks.picker.Highlight[]
  local info = status_icons[item.status_code] or { icon = "?", hl = "NonText" }

  ret[#ret + 1] = { info.icon .. " ", info.hl }
  ret[#ret + 1] = { item.file or item.text }

  return ret
end

--- Open the changed file picker.
---@param opts? { args?: string[] } optional git diff arguments
function M.open(opts)
  opts = opts or {}
  local args = opts.args or {}

  local git = require("diffv.git")
  local provider = require("diffv.git.provider")
  local parse = require("diffv.git.parse")

  local root = git.repo_root()
  if not root then
    vim.notify("diffv: not in a git repository", vim.log.levels.ERROR)
    return
  end

  local files, err = provider.changed_files_sync(args)
  if err or #files == 0 then
    vim.notify("diffv: no changes found", vim.log.levels.INFO)
    return
  end

  -- Determine revision for preview context
  local rev = nil
  for _, a in ipairs(args) do
    if not a:match("^%-") then
      rev = a
      break
    end
  end

  -- Build picker items
  local items = {}
  for _, f in ipairs(files) do
    items[#items + 1] = {
      text = f.path,
      file = f.path,
      cwd = root,
      status_code = f.status:sub(1, 1),
      status_label = status_labels[f.status:sub(1, 1)] or f.status,
      diff_args = args,
      rev = rev,
    }
  end

  Snacks.picker({
    title = "diffv: changed files",
    items = items,
    format = format_item,
    preview = diff_preview,
    layout = { preset = "default" },
    confirm = function(picker, item)
      picker:close()
      if item and item.file then
        require("diffv").open(args, item.file)
      end
    end,
  })
end

return M
