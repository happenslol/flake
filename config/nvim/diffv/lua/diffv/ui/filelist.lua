--- Persistent file list panel for navigating multi-file diffs.
local M = {}

local status_icons = {
  M = { icon = "~", hl = "DiffChange" },
  A = { icon = "+", hl = "DiffAdd" },
  D = { icon = "-", hl = "DiffDelete" },
  R = { icon = "→", hl = "DiffChange" },
}

local ns = vim.api.nvim_create_namespace("diffv_filelist")

--- @class diffv.FileListState
--- @field buf number
--- @field win number
--- @field width number -- configured width in columns
--- @field files { path: string, status: string }[]
--- @field current number -- 1-indexed, currently selected file
--- @field on_select fun(index: number) -- callback when a file is selected

--- Active file list state.
---@type diffv.FileListState?
M.state = nil

--- Render the file list content into the buffer.
---@param state diffv.FileListState
local function render(state)
  local buf = state.buf
  vim.bo[buf].modifiable = true

  local lines = {}
  for _, f in ipairs(state.files) do
    local code = f.status:sub(1, 1)
    local info = status_icons[code] or { icon = "?", hl = "NonText" }
    lines[#lines + 1] = info.icon .. " " .. f.path
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Highlight current file
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if state.current >= 1 and state.current <= #state.files then
    vim.api.nvim_buf_set_extmark(buf, ns, state.current - 1, 0, {
      end_row = state.current,
      hl_group = "CursorLine",
      hl_eol = true,
    })
  end

  -- Status icon highlights
  for i, f in ipairs(state.files) do
    local code = f.status:sub(1, 1)
    local info = status_icons[code]
    if info then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
        end_row = i - 1,
        end_col = #info.icon,
        hl_group = info.hl,
      })
    end
  end
end

--- Create the file list panel.
---@param files { path: string, status: string }[]
---@param current number 1-indexed current file
---@param on_select fun(index: number)
---@return diffv.FileListState
function M.create(files, current, on_select)
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
  local max_len = 0
  for _, f in ipairs(files) do
    max_len = math.max(max_len, #f.path + 3)
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
  }

  render(state)

  -- Place cursor on current file
  if current >= 1 and current <= #files then
    vim.api.nvim_win_set_cursor(win, { current, 0 })
  end

  local function select_at_cursor()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    if row >= 1 and row <= #state.files then
      state.current = row
      render(state)
      state.on_select(row)
    end
  end

  -- Keymaps
  vim.keymap.set("n", "<CR>", select_at_cursor, { buffer = buf, desc = "Open file diff" })
  vim.keymap.set("n", "<2-LeftMouse>", select_at_cursor, { buffer = buf, desc = "Open file diff" })

  vim.keymap.set("n", "q", function()
    require("diffv").close()
  end, { buffer = buf, desc = "Close diffv" })

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
    vim.api.nvim_win_set_cursor(M.state.win, { index, 0 })
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
