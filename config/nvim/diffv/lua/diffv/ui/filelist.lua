--- Persistent file list panel for navigating multi-file diffs.
local M = {}

local status_icons = {
  M = { hl = "DiffvStatusModified" },
  A = { hl = "DiffvStatusAdded" },
  D = { hl = "DiffvStatusDeleted" },
  R = { hl = "DiffvStatusRenamed" },
}

---@param code string single-char status code (M/A/D/R)
---@return string icon
local function status_icon(code)
  local config = require("diffv.config").values
  return config.status_icons[code] or "?"
end

--- Get file icon and highlight from mini.icons (with fallback).
---@param path string file path
---@return string icon
---@return string? hl highlight group
local function file_icon(path)
  local ok, icons = pcall(require, "mini.icons")
  if ok then
    local icon, hl = icons.get("file", path)
    return icon, hl
  end
  return "", nil
end

local ns = vim.api.nvim_create_namespace("diffv_filelist")

local HEADER_LINES = 3 -- "diffv", "old..new", ""

--- @class diffv.FileListState
--- @field buf number
--- @field win number
--- @field width number -- configured width in columns
--- @field files { path: string, status: string }[]
--- @field current number -- 1-indexed, currently selected file
--- @field on_select fun(index: number) -- callback when a file is selected
--- @field diff_label string -- e.g. "HEAD → working tree"

--- Active file list state.
---@type diffv.FileListState?
M.state = nil

--- Render the file list content into the buffer.
---@param state diffv.FileListState
local function render(state)
  local buf = state.buf
  vim.bo[buf].modifiable = true

  -- Header
  local lines = {
    " diffv",
    " " .. state.diff_label,
    "",
  }

  local icon_data = {} -- per-file { status_icon, ft_icon, ft_hl, ft_offset }
  for _, f in ipairs(state.files) do
    local code = f.status:sub(1, 1)
    local si = status_icon(code)
    local ft_icon, ft_hl = file_icon(f.path)
    local line = " " .. si .. " " .. ft_icon .. " " .. f.path
    lines[#lines + 1] = line
    icon_data[#icon_data + 1] = {
      status_offset = 1, -- after leading space
      status_icon = si,
      ft_icon = ft_icon,
      ft_hl = ft_hl,
      ft_offset = 1 + #si + 1, -- after leading space + status + space
    }
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  -- Header highlights
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    end_row = 0,
    end_col = #lines[1],
    hl_group = "Bold",
  })
  vim.api.nvim_buf_set_extmark(buf, ns, 1, 0, {
    end_row = 1,
    end_col = #lines[2],
    hl_group = "Comment",
  })

  -- Highlight current file
  local cur_row = state.current - 1 + HEADER_LINES
  if state.current >= 1 and state.current <= #state.files then
    vim.api.nvim_buf_set_extmark(buf, ns, cur_row, 0, {
      end_row = cur_row + 1,
      hl_group = "CursorLine",
      hl_eol = true,
    })
  end

  -- Status and file type icon highlights
  for i, f in ipairs(state.files) do
    local row = i - 1 + HEADER_LINES
    local code = f.status:sub(1, 1)
    local info = status_icons[code]
    local id = icon_data[i]

    if info then
      vim.api.nvim_buf_set_extmark(buf, ns, row, id.status_offset, {
        end_row = row,
        end_col = id.status_offset + #id.status_icon,
        hl_group = info.hl,
        priority = 200,
      })
    end

    if id.ft_hl then
      vim.api.nvim_buf_set_extmark(buf, ns, row, id.ft_offset, {
        end_row = row,
        end_col = id.ft_offset + #id.ft_icon,
        hl_group = id.ft_hl,
        priority = 200,
      })
    end
  end
end

--- Create the file list panel.
---@param files { path: string, status: string }[]
---@param current number 1-indexed current file
---@param on_select fun(index: number)
---@param diff_label? string e.g. "HEAD → working tree"
---@return diffv.FileListState
function M.create(files, current, on_select, diff_label)
  if M.state then
    M.destroy()
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "diffv-filelist"
  vim.api.nvim_buf_set_name(buf, "diffv://files")

  -- Find max filename length for sizing, clamped to reasonable range
  -- +6 accounts for padding + status icon + space + ft icon + space
  local max_len = 0
  for _, f in ipairs(files) do
    max_len = math.max(max_len, #f.path + 6)
  end
  local width = math.max(25, math.min(max_len, 50))

  -- Open as a left-side vertical split
  vim.cmd("topleft " .. width .. "vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].winfixwidth = true
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].foldmethod = "manual"
  vim.wo[win].foldlevel = 99

  ---@type diffv.FileListState
  local state = {
    buf = buf,
    win = win,
    width = width,
    files = files,
    current = current,
    on_select = on_select,
    diff_label = diff_label or "",
  }

  render(state)

  -- Place cursor on current file (offset by header)
  if current >= 1 and current <= #files then
    vim.api.nvim_win_set_cursor(win, { current + HEADER_LINES, 0 })
  end

  local function select_at_cursor()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local file_index = row - HEADER_LINES
    if file_index >= 1 and file_index <= #state.files then
      state.current = file_index
      render(state)
      state.on_select(file_index)
    end
  end

  -- Keymaps — "select" is filelist-specific; the rest come from actions module
  local builtin_actions = require("diffv.actions")
  local local_actions = {
    select = select_at_cursor,
  }

  local merged = require("diffv.config").keymaps_for("filelist")
  for key, action in pairs(merged) do
    local fn, desc
    if type(action) == "function" then
      fn = action
      desc = "diffv: custom"
    elseif type(action) == "string" then
      fn = local_actions[action] or builtin_actions[action]
      desc = "diffv: " .. action:gsub("_", " ")
    end
    if fn then
      vim.keymap.set("n", key, fn, { buffer = buf, desc = desc })
    end
  end

  M.state = state

  return state
end

--- Update which file is currently selected (highlight only, no callback).
---@param index number
function M.set_current(index)
  if not M.state then
    return
  end
  M.state.current = index
  render(M.state)
  -- Move cursor in file list window if it's still valid
  if vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_set_cursor(M.state.win, { index + HEADER_LINES, 0 })
  end
end

--- Snapshot the current window width so it survives layout changes.
function M.save_width()
  if not M.state then
    return
  end
  if vim.api.nvim_win_is_valid(M.state.win) then
    M.state.width = vim.api.nvim_win_get_width(M.state.win)
  end
end

--- Restore the file list window to its last known width.
function M.restore_width()
  if not M.state then
    return
  end
  if vim.api.nvim_win_is_valid(M.state.win) then
    vim.api.nvim_win_set_width(M.state.win, M.state.width)
  end
end

--- Destroy the file list panel.
function M.destroy()
  if not M.state then
    return
  end
  local state = M.state
  M.state = nil
  if vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end
end

return M
