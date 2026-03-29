--- Side-by-side diff renderer.
--- Creates a vertical split with old version (left) and new version (right),
--- with line padding for alignment and synchronized scrolling.
local M = {}

--- Line entry for a side buffer. Extends diffv.Line with alignment info.
---@class diffv.SideLine
---@field type "context" | "add" | "delete" | "change" | "padding"
---@field content string display content
---@field lnum? number original file line number
---@field side? "old" | "new"
---@field paired_content? string content of the paired changed line (for word diff)

--- Build aligned line maps for left (old) and right (new) buffers.
--- Inserts padding lines so that corresponding changes align vertically.
---@param diff_result diffv.DiffResult
---@return diffv.SideLine[] left_map
---@return diffv.SideLine[] right_map
function M.build_line_maps(diff_result)
  local left = {} ---@type diffv.SideLine[]
  local right = {} ---@type diffv.SideLine[]
  local old_lines = diff_result.old_lines
  local new_lines = diff_result.new_lines

  -- Track which old/new lines we've placed
  local old_idx = 1
  local new_idx = 1

  for _, hunk in ipairs(diff_result.hunks) do
    -- Emit context lines before this hunk (lines between last hunk end and this hunk start)
    while old_idx < hunk.old_start and new_idx < hunk.new_start do
      left[#left + 1] = { type = "context", content = old_lines[old_idx] or "", lnum = old_idx, side = "old" }
      right[#right + 1] = { type = "context", content = new_lines[new_idx] or "", lnum = new_idx, side = "new" }
      old_idx = old_idx + 1
      new_idx = new_idx + 1
    end

    -- Collect deletes and adds from this hunk
    local deletes = {} ---@type diffv.Line[]
    local adds = {} ---@type diffv.Line[]
    local hunk_context = {} ---@type diffv.Line[]

    for _, line in ipairs(hunk.lines) do
      if line.type == "delete" then
        deletes[#deletes + 1] = line
      elseif line.type == "add" then
        adds[#adds + 1] = line
      elseif line.type == "context" then
        -- Flush pending deletes/adds before emitting context
        if #deletes > 0 or #adds > 0 then
          M._emit_changes(left, right, deletes, adds)
          deletes = {}
          adds = {}
        end
        hunk_context[#hunk_context + 1] = line
        left[#left + 1] = { type = "context", content = line.content, lnum = line.old_lnum, side = "old" }
        right[#right + 1] = { type = "context", content = line.content, lnum = line.new_lnum, side = "new" }
      end
    end

    -- Flush remaining deletes/adds
    if #deletes > 0 or #adds > 0 then
      M._emit_changes(left, right, deletes, adds)
    end

    -- Advance indices past this hunk
    old_idx = hunk.old_start + hunk.old_count
    new_idx = hunk.new_start + hunk.new_count
  end

  -- Emit remaining context after last hunk
  while old_idx <= #old_lines and new_idx <= #new_lines do
    left[#left + 1] = { type = "context", content = old_lines[old_idx] or "", lnum = old_idx, side = "old" }
    right[#right + 1] = { type = "context", content = new_lines[new_idx] or "", lnum = new_idx, side = "new" }
    old_idx = old_idx + 1
    new_idx = new_idx + 1
  end
  -- Handle case where one side has more lines
  while old_idx <= #old_lines do
    left[#left + 1] = { type = "delete", content = old_lines[old_idx], lnum = old_idx, side = "old" }
    right[#right + 1] = { type = "padding", content = "", side = "new" }
    old_idx = old_idx + 1
  end
  while new_idx <= #new_lines do
    left[#left + 1] = { type = "padding", content = "", side = "old" }
    right[#right + 1] = { type = "add", content = new_lines[new_idx], lnum = new_idx, side = "new" }
    new_idx = new_idx + 1
  end

  return left, right
end

--- Emit aligned change/padding lines for a group of deletes and adds.
---@param left diffv.SideLine[]
---@param right diffv.SideLine[]
---@param deletes diffv.Line[]
---@param adds diffv.Line[]
function M._emit_changes(left, right, deletes, adds)
  local max = math.max(#deletes, #adds)
  for i = 1, max do
    local del = deletes[i]
    local add = adds[i]
    if del and add then
      -- Paired change — mark as "change" for word-level diff
      left[#left + 1] = {
        type = "change",
        content = del.content,
        lnum = del.old_lnum,
        side = "old",
        paired_content = add.content,
      }
      right[#right + 1] = {
        type = "change",
        content = add.content,
        lnum = add.new_lnum,
        side = "new",
        paired_content = del.content,
      }
    elseif del then
      left[#left + 1] = { type = "delete", content = del.content, lnum = del.old_lnum, side = "old" }
      right[#right + 1] = { type = "padding", content = "", side = "new" }
    elseif add then
      left[#left + 1] = { type = "padding", content = "", side = "old" }
      right[#right + 1] = { type = "add", content = add.content, lnum = add.new_lnum, side = "new" }
    end
  end
end

--- Set window-local options for a diff pane.
---@param win number window handle
local function set_win_opts(win)
  vim.wo[win].scrollbind = true
  vim.wo[win].cursorbind = true
  vim.wo[win].foldmethod = "manual"
  vim.wo[win].number = true
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
end

--- Render a side-by-side diff view.
---@param diff_result diffv.DiffResult
---@param filetype string filetype for syntax highlighting
---@param config diffv.Config
---@return number[] buffers created buffer handles
---@return number[] windows created window handles
---@return number tabnr tab page number
function M.render(diff_result, filetype, config)
  local buffer = require("diffv.buffer")
  local highlights = require("diffv.ui.highlights")

  local left_map, right_map = M.build_line_maps(diff_result)

  -- Extract display lines
  local left_lines = {}
  local right_lines = {}
  for _, entry in ipairs(left_map) do
    left_lines[#left_lines + 1] = entry.content
  end
  for _, entry in ipairs(right_map) do
    right_lines[#right_lines + 1] = entry.content
  end

  -- Create buffers
  local left_buf = buffer.create(filetype, "diffv://old")
  local right_buf = buffer.create(filetype, "diffv://new")

  buffer.set_lines(left_buf, left_lines)
  buffer.set_lines(right_buf, right_lines)

  -- Create layout: new tab with vertical split
  vim.cmd("tabnew")
  local tabnr = vim.fn.tabpagenr()
  local left_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(left_win, left_buf)

  vim.cmd("vsplit")
  local right_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(right_win, right_buf)

  -- Set window options
  set_win_opts(left_win)
  set_win_opts(right_win)

  -- Sync scroll positions
  vim.cmd("windo syncbind")

  -- Apply highlights
  highlights.apply_side(left_buf, left_map, config)
  highlights.apply_side(right_buf, right_map, config)

  -- Set up close keybind on both buffers
  local close_key = config.keymaps.close
  for _, buf in ipairs({ left_buf, right_buf }) do
    vim.keymap.set("n", close_key, function()
      require("diffv").close()
    end, { buffer = buf, desc = "Close diffv" })
  end

  return { left_buf, right_buf }, { left_win, right_win }, tabnr
end

return M
