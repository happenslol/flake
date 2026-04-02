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

local status_hls = {
  M = "DiffvStatusModified",
  A = "DiffvStatusAdded",
  D = "DiffvStatusDeleted",
  R = "DiffvStatusRenamed",
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
  local config = require("diffv.config").values
  local icon = config.status_icons[item.status_code] or "?"
  local hl = status_hls[item.status_code] or "NonText"

  ret[#ret + 1] = { icon .. " ", hl }
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

--- Format a git log entry for display.
---@param item snacks.picker.finder.Item
---@param picker snacks.Picker
local function format_log_item(item, picker)
  local ret = {} ---@type snacks.picker.Highlight[]
  ret[#ret + 1] = { item.hash .. " ", "Identifier" }
  ret[#ret + 1] = { item.subject .. " ", "Normal" }
  ret[#ret + 1] = { item.author, "Special" }
  ret[#ret + 1] = { " " .. item.date, "Comment" }
  return ret
end

local preview_ns = vim.api.nvim_create_namespace("diffv_log_preview")

--- Apply highlights to the log preview buffer.
---@param buf number
---@param lines string[]
---@param body_start number 0-indexed row where the body begins (after blank line)
---@param stat_start number 0-indexed row where the diffstat begins
local function highlight_preview(buf, lines, body_start, stat_start)
  -- Line 0: hash
  vim.api.nvim_buf_set_extmark(buf, preview_ns, 0, 0, {
    end_row = 0,
    end_col = #lines[1],
    hl_group = "Identifier",
  })

  -- Line 1: subject
  if #lines > 1 then
    vim.api.nvim_buf_set_extmark(buf, preview_ns, 1, 0, {
      end_row = 1,
      end_col = #lines[2],
      hl_group = "Title",
    })
  end

  -- Diffstat lines: highlight insertions/deletions
  for i = stat_start, #lines - 1 do
    local line = lines[i + 1]
    -- Match the +/- part at the end of stat lines (e.g. "| 42 +++---")
    local bar_pos = line:find("|")
    if bar_pos then
      -- Highlight filename
      vim.api.nvim_buf_set_extmark(buf, preview_ns, i, 0, {
        end_row = i,
        end_col = bar_pos - 1,
        hl_group = "Normal",
      })
      -- Highlight + chars
      for pos in line:gmatch("()+") do
        vim.api.nvim_buf_set_extmark(buf, preview_ns, i, pos - 1, {
          end_row = i,
          end_col = pos - 1 + #line:match("%++", pos),
          hl_group = "DiffAdd",
        })
      end
      -- Highlight - chars
      for pos in line:gmatch("()%-+") do
        if pos > bar_pos then
          vim.api.nvim_buf_set_extmark(buf, preview_ns, i, pos - 1, {
            end_row = i,
            end_col = pos - 1 + #line:match("%-+", pos),
            hl_group = "DiffDelete",
          })
        end
      end
    -- Summary line (e.g. "3 files changed, 10 insertions(+), 5 deletions(-)")
    elseif line:match("file.*changed") then
      vim.api.nvim_buf_set_extmark(buf, preview_ns, i, 0, {
        end_row = i,
        end_col = #line,
        hl_group = "Comment",
      })
    end
  end
end

--- Preview for a log entry: show commit info and diffstat.
---@param ctx snacks.picker.preview.ctx
local function log_preview(ctx)
  local item = ctx.item
  if not item or not item.hash then
    return
  end

  local git_mod = require("diffv.git")
  local stdout, _, code = git_mod.run_sync({
    "show",
    "--stat",
    "--format=%H%n%s%n%n%b",
    item.hash,
  })
  if code ~= 0 then
    return
  end

  local lines = vim.split(vim.trim(stdout), "\n")

  local buf = ctx.preview:scratch()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Find where body ends and diffstat begins (after the format output)
  -- Format is: hash, subject, blank, body..., diffstat...
  local body_start = 3 -- 0-indexed, after hash + subject + blank
  local stat_start = #lines
  for i = #lines, 1, -1 do
    if lines[i]:match("|") or lines[i]:match("file.*changed") then
      stat_start = i - 1
    else
      break
    end
  end

  highlight_preview(buf, lines, body_start, stat_start)
end

--- Open the git log picker.
---@param opts? { limit?: number }
function M.log(opts)
  opts = opts or {}

  local git_mod = require("diffv.git")
  local provider = require("diffv.git.provider")

  local root = git_mod.repo_root()
  if not root then
    vim.notify("diffv: not in a git repository", vim.log.levels.ERROR)
    return
  end

  local entries, err = provider.log_sync(opts.limit)
  if err or #entries == 0 then
    vim.notify("diffv: no log entries found", vim.log.levels.INFO)
    return
  end

  local items = {}
  for _, e in ipairs(entries) do
    items[#items + 1] = {
      text = e.hash .. " " .. e.subject .. " " .. e.author,
      hash = e.hash,
      subject = e.subject,
      author = e.author,
      date = e.date,
    }
  end

  Snacks.picker({
    title = "diffv: git log",
    items = items,
    format = format_log_item,
    preview = log_preview,
    layout = { preset = "default" },
    confirm = function(picker, item)
      picker:close()
      if item and item.hash then
        require("diffv").open_commit(item.hash)
      end
    end,
  })
end

return M
