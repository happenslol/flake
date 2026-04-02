--- Central state for a diffv tab view.
--- One instance fully describes what's shown in a tab:
--- which revisions, which files, which file is selected, layout, etc.
local M = {}

---@class diffv.ViewState
---@field old_rev string -- left side revision (e.g. "HEAD", "abc~", "main")
---@field new_rev string|nil -- right side: nil = working tree, ":" = index, or a rev
---@field root string -- git repo root
---@field files { path: string, status: string }[]
---@field current_file number -- 1-indexed
---@field layout "side_by_side"|"inline"
---@field context_lines number
---@field _saved_context number|nil -- for toggle_context
---@field tabnr number
---@field diff_bufs number[]
---@field diff_wins number[]
---@field _closing boolean
---@field _augroup number
---@field _diff_result diffv.DiffResult|nil

local ViewState = {}
ViewState.__index = ViewState

--- The active view state (singleton for now).
---@type diffv.ViewState|nil
M.active = nil

--- Parse command arguments into normalized old_rev / new_rev / diff_args.
---@param args string[]
---@return string old_rev
---@return string|nil new_rev
---@return string[] diff_args for git diff --name-status
local function parse_args(args)
  local is_cached = vim.tbl_contains(args, "--cached")
  if is_cached then
    return "HEAD", ":", { "--cached" }
  end

  local rev
  for _, a in ipairs(args) do
    if not a:match("^%-") then
      rev = a
      break
    end
  end

  if rev and rev:match("%.%.") then
    local rev_a, rev_b = rev:match("^(.+)%.%.(.+)$")
    return rev_a, rev_b, { rev_a .. ".." .. rev_b }
  elseif rev then
    return rev .. "~", rev, { rev .. "~.." .. rev }
  else
    return "HEAD", nil, {}
  end
end

--- Create a new ViewState from command arguments.
---@param args string[]
---@param opts? { file_path?: string, layout?: string }
---@return diffv.ViewState|nil
function M.create(args, opts)
  opts = opts or {}
  local git = require("diffv.git")
  local provider = require("diffv.git.provider")
  local config = require("diffv.config").values

  local root = git.repo_root()
  if not root then
    vim.notify("diffv: not in a git repository", vim.log.levels.ERROR)
    return nil
  end

  local old_rev, new_rev, diff_args = parse_args(args)

  local files
  if opts.file_path then
    files = { { path = opts.file_path, status = "M" } }
  else
    local err
    files, err = provider.changed_files_sync(diff_args)
    if err or #files == 0 then
      vim.notify("diffv: no changes found", vim.log.levels.INFO)
      return nil
    end
  end

  return setmetatable({
    old_rev = old_rev,
    new_rev = new_rev,
    root = root,
    files = files,
    current_file = 1,
    layout = opts.layout or config.layout,
    context_lines = config.context,
    _saved_context = nil,
    tabnr = -1,
    diff_bufs = {},
    diff_wins = {},
    _closing = false,
    _augroup = vim.api.nvim_create_augroup("diffv_winguard", { clear = true }),
    _diff_result = nil,
  }, ViewState)
end

---@return string
function ViewState:old_label()
  return self.old_rev
end

---@return string
function ViewState:new_label()
  if self.new_rev == nil then
    return "working tree"
  end
  if self.new_rev == ":" then
    return "staged"
  end
  return self.new_rev
end

--- Fetch old and new file content for a path.
---@param rel_path string
---@return string old_text
---@return string new_text
function ViewState:file_content(rel_path)
  local provider = require("diffv.git.provider")
  local old_text = provider.get_file_sync(self.old_rev, rel_path) or ""
  local new_text
  if self.new_rev == nil then
    new_text = provider.get_working_copy(self.root .. "/" .. rel_path) or ""
  else
    new_text = provider.get_file_sync(self.new_rev, rel_path) or ""
  end
  return old_text, new_text
end

--- Open the view: create tab, filelist if needed, render first file.
function ViewState:open()
  local filelist = require("diffv.ui.filelist")

  if M.active then
    M.active:destroy()
  end
  M.active = self

  vim.cmd("tabnew")
  self.tabnr = vim.fn.tabpagenr()

  if #self.files > 1 then
    filelist.create(self.files, 1, function(index)
      self:select_file(index)
    end)
  end

  self:select_file(1)
end

--- Switch to a different file by index.
---@param index number 1-indexed
function ViewState:select_file(index)
  local f = self.files[index]
  if not f then
    return
  end

  -- Preserve context state modified via ui.adjust_context / ui.toggle_context
  self:_sync_from_ui()

  local diff_engine = require("diffv.diff")
  local filelist = require("diffv.ui.filelist")
  local ui = require("diffv.ui")
  local config = require("diffv.config").values

  local rel_path = f.path
  local filetype = vim.filetype.match({ filename = rel_path }) or ""

  local old_text, new_text = self:file_content(rel_path)
  if old_text == new_text then
    vim.notify("diffv: no differences in " .. rel_path, vim.log.levels.INFO)
    return
  end

  local diff_result = diff_engine.diff(old_text, new_text)
  self._diff_result = diff_result
  self.current_file = index

  self:_ensure_windows()

  local file_info = {
    path = rel_path,
    old_label = self:old_label(),
    new_label = self:new_label(),
  }

  local buffers, windows = self:_render(diff_result, filetype, config, file_info)
  self.diff_bufs = buffers
  self.diff_wins = windows

  -- Set ui.active so context folding and keybinds work
  ui.active = {
    buffers = buffers,
    windows = windows,
    tabnr = self.tabnr,
    layout = self.layout,
    diff_result = diff_result,
    context_lines = self.context_lines,
    _saved_context = self._saved_context,
    filetype = filetype,
    file_info = file_info,
    file_changes = {},
    current_index = index,
    config = config,
    close = function()
      self:destroy()
    end,
    toggle_layout_impl = function()
      self:toggle_layout()
    end,
  }
  ui.apply_context(ui.active)

  self:_setup_keymaps(buffers, config)

  if filelist.state then
    filelist.set_current(index)
  end

  self:_setup_guards()
end

--- Toggle between side_by_side and inline.
function ViewState:toggle_layout()
  self:_sync_from_ui()
  if self.layout == "side_by_side" then
    self.layout = "inline"
  else
    self.layout = "side_by_side"
  end
  self:select_file(self.current_file)
end

--- Sync mutable UI state (context lines) back into the ViewState.
function ViewState:_sync_from_ui()
  local ui = require("diffv.ui")
  if ui.active then
    self.context_lines = ui.active.context_lines
    self._saved_context = ui.active._saved_context
  end
end

--- Destroy the view: close tab, clean up everything.
function ViewState:destroy()
  if self._closing then
    return
  end
  self._closing = true

  local ui = require("diffv.ui")
  local filelist = require("diffv.ui.filelist")

  pcall(vim.api.nvim_del_augroup_by_name, "diffv_winguard")

  ui.active = nil
  filelist.destroy()

  -- Restore diffopt
  if self.layout == "side_by_side" then
    local opts = vim.opt.diffopt:get()
    local new_opts = {}
    for _, o in ipairs(opts) do
      if not o:match("^context:") then
        new_opts[#new_opts + 1] = o
      end
    end
    vim.opt.diffopt = new_opts
  end

  -- Close the tab if possible
  if self.tabnr and vim.fn.tabpagenr("$") > 1 then
    -- Find any valid window to identify the tab
    local all_wins = vim.list_extend({}, self.diff_wins)
    if filelist.state and vim.api.nvim_win_is_valid(filelist.state.win) then
      all_wins[#all_wins + 1] = filelist.state.win
    end
    for _, win in ipairs(all_wins) do
      if vim.api.nvim_win_is_valid(win) then
        local win_tabnr = vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(win))
        pcall(vim.cmd, win_tabnr .. "tabclose")
        if M.active == self then
          M.active = nil
        end
        return
      end
    end
  end

  -- Fallback: close windows individually
  for _, win in ipairs(self.diff_wins) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  for _, buf in ipairs(self.diff_bufs) do
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end

  if M.active == self then
    M.active = nil
  end
end

--- Check if current windows can be reused for the given layout.
---@param layout string
---@return boolean
function ViewState:_can_reuse(layout)
  if layout == "side_by_side" then
    return #self.diff_wins == 2
      and vim.api.nvim_win_is_valid(self.diff_wins[1])
      and vim.api.nvim_win_is_valid(self.diff_wins[2])
  else
    return #self.diff_wins == 1 and vim.api.nvim_win_is_valid(self.diff_wins[1])
  end
end

--- Ensure diff windows exist, reusing if layout matches.
function ViewState:_ensure_windows()
  local filelist = require("diffv.ui.filelist")

  if self:_can_reuse(self.layout) then
    -- Swap out old buffers with placeholders to keep windows alive
    self._closing = true
    for i, buf in ipairs(self.diff_bufs) do
      if vim.api.nvim_buf_is_valid(buf) then
        local placeholder = vim.api.nvim_create_buf(false, true)
        vim.bo[placeholder].bufhidden = "wipe"
        if self.diff_wins[i] and vim.api.nvim_win_is_valid(self.diff_wins[i]) then
          vim.api.nvim_win_set_buf(self.diff_wins[i], placeholder)
        end
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end
    end
    self.diff_bufs = {}
    self._closing = false
    return
  end

  -- Layout changed or windows gone — full cleanup + recreate
  self._closing = true
  for _, win in ipairs(self.diff_wins) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  for _, buf in ipairs(self.diff_bufs) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  self.diff_bufs = {}
  self.diff_wins = {}
  self._closing = false

  if filelist.state and vim.api.nvim_win_is_valid(filelist.state.win) then
    filelist.save_width()
    vim.api.nvim_set_current_win(filelist.state.win)
    local cur = vim.api.nvim_get_current_win()
    vim.cmd("wincmd l")
    if vim.api.nvim_get_current_win() == cur then
      vim.cmd("rightbelow vnew")
      vim.bo[vim.api.nvim_get_current_buf()].bufhidden = "wipe"
    end
    filelist.restore_width()
  end
end

--- Render diff content into windows.
---@param diff_result diffv.DiffResult
---@param filetype string
---@param config diffv.Config
---@param file_info { path: string, old_label: string, new_label: string }
---@return number[] buffers
---@return number[] windows
function ViewState:_render(diff_result, filetype, config, file_info)
  local buffer = require("diffv.buffer")

  if self.layout == "side_by_side" then
    local sbs = require("diffv.ui.side_by_side")

    local left_buf = buffer.create(filetype, "diffv://" .. file_info.path .. " (" .. file_info.old_label .. ")")
    local right_buf = buffer.create(filetype, "diffv://" .. file_info.path .. " (" .. file_info.new_label .. ")")
    buffer.set_lines(left_buf, diff_result.old_lines)
    buffer.set_lines(right_buf, diff_result.new_lines)

    local left_win, right_win
    if #self.diff_wins == 2 then
      left_win, right_win = self.diff_wins[1], self.diff_wins[2]
      vim.api.nvim_win_call(left_win, function()
        vim.cmd("diffoff")
      end)
      vim.api.nvim_win_call(right_win, function()
        vim.cmd("diffoff")
      end)
      vim.api.nvim_win_set_buf(left_win, left_buf)
      vim.api.nvim_win_set_buf(right_win, right_buf)
    else
      left_win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(left_win, left_buf)
      vim.cmd("vsplit")
      right_win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(right_win, right_buf)
    end

    vim.api.nvim_win_call(left_win, function()
      vim.cmd("diffthis")
    end)
    vim.api.nvim_win_call(right_win, function()
      vim.cmd("diffthis")
    end)

    for _, win in ipairs({ left_win, right_win }) do
      vim.wo[win].foldmethod = "diff"
      vim.wo[win].foldlevel = 0
      vim.wo[win].number = true
      vim.wo[win].relativenumber = false
      vim.wo[win].signcolumn = "no"
      vim.wo[win].wrap = false
      vim.wo[win].cursorline = true
    end

    -- Redirect vim's Diff* highlights to our custom groups (red left, green right)
    sbs.set_winhighlight(left_win, right_win, config)
    sbs.apply_highlights(left_buf, right_buf, diff_result, config)

    return { left_buf, right_buf }, { left_win, right_win }
  else
    local inline = require("diffv.ui.inline")

    local buf = buffer.create(
      filetype,
      "diffv://" .. file_info.path .. " (" .. file_info.old_label .. " → " .. file_info.new_label .. ")"
    )
    buffer.set_lines(buf, diff_result.new_lines)

    local win
    if #self.diff_wins == 1 then
      win = self.diff_wins[1]
    else
      win = vim.api.nvim_get_current_win()
    end
    vim.api.nvim_win_set_buf(win, buf)

    vim.wo[win].number = true
    vim.wo[win].relativenumber = false
    vim.wo[win].signcolumn = "no"
    vim.wo[win].wrap = false
    vim.wo[win].cursorline = true
    vim.wo[win].foldmethod = "manual"
    vim.wo[win].foldlevel = 0

    inline.apply_overlay(buf, diff_result, config, filetype)

    return { buf }, { win }
  end
end

--- Set up keymaps on diff buffers.
---@param buffers number[]
---@param config diffv.Config
function ViewState:_setup_keymaps(buffers, config)
  local ui = require("diffv.ui")
  local km = config.keymaps

  for _, buf in ipairs(buffers) do
    vim.keymap.set("n", km.close, function()
      self:destroy()
    end, { buffer = buf, desc = "Close diffv" })

    vim.keymap.set("n", km.increase_context, function()
      ui.adjust_context(5)
    end, { buffer = buf, desc = "Increase diff context" })

    vim.keymap.set("n", km.decrease_context, function()
      ui.adjust_context(-5)
    end, { buffer = buf, desc = "Decrease diff context" })

    vim.keymap.set("n", km.toggle_context, function()
      ui.toggle_context()
    end, { buffer = buf, desc = "Toggle context folding" })

    vim.keymap.set("n", km.toggle_layout, function()
      ui.toggle_layout()
    end, { buffer = buf, desc = "Toggle diff layout" })
  end
end

--- Attach WinClosed guards to tear down the view if any window is closed externally.
function ViewState:_setup_guards()
  local filelist = require("diffv.ui.filelist")

  self._augroup = vim.api.nvim_create_augroup("diffv_winguard", { clear = true })

  local guard_wins = {}
  if filelist.state and vim.api.nvim_win_is_valid(filelist.state.win) then
    guard_wins[#guard_wins + 1] = filelist.state.win
  end
  for _, win in ipairs(self.diff_wins) do
    if vim.api.nvim_win_is_valid(win) then
      guard_wins[#guard_wins + 1] = win
    end
  end

  for _, win in ipairs(guard_wins) do
    vim.api.nvim_create_autocmd("WinClosed", {
      group = self._augroup,
      pattern = tostring(win),
      once = true,
      callback = function()
        if self._closing then
          return
        end
        vim.schedule(function()
          self:destroy()
        end)
      end,
    })
  end
end

return M
