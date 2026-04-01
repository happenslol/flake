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

--- Resolve old/new file content and labels from diff args.
---@param args string[]
---@param rel_path string
---@param root string
---@return string? old_text
---@return string? new_text
---@return string old_label
---@return string new_label
local function resolve_file(args, rel_path, root)
  local provider = require("diffv.git.provider")

  local is_cached = vim.tbl_contains(args, "--cached")
  local rev
  for _, a in ipairs(args) do
    if not a:match("^%-") then
      rev = a
      break
    end
  end

  if is_cached then
    return provider.get_file_sync("HEAD", rel_path), provider.get_file_sync(":", rel_path), "HEAD", "staged"
  elseif rev and rev:match("%.%.") then
    local rev_a, rev_b = rev:match("^(.+)%.%.(.+)$")
    return provider.get_file_sync(rev_a, rel_path), provider.get_file_sync(rev_b, rel_path), rev_a, rev_b
  elseif rev then
    return provider.get_file_sync(rev .. "~", rel_path), provider.get_file_sync(rev, rel_path), rev .. "~", rev
  else
    local abs_path = root .. "/" .. rel_path
    return provider.get_file_sync("HEAD", rel_path), provider.get_working_copy(abs_path), "HEAD", "working tree"
  end
end

--- Render a diff into existing windows (no tab creation).
--- When existing_wins are provided and match the layout, reuses them.
---@param diff_result diffv.DiffResult
---@param filetype string
---@param config diffv.Config
---@param file_info { path: string, old_label: string, new_label: string }
---@param layout string
---@param existing_wins? number[] windows to reuse
---@return number[] buffers
---@return number[] windows
local function render_diff_inplace(diff_result, filetype, config, file_info, layout, existing_wins)
  local buffer = require("diffv.buffer")

  if layout == "side_by_side" then
    local left_buf = buffer.create(filetype, "diffv://" .. file_info.path .. " (" .. file_info.old_label .. ")")
    local right_buf = buffer.create(filetype, "diffv://" .. file_info.path .. " (" .. file_info.new_label .. ")")
    buffer.set_lines(left_buf, diff_result.old_lines)
    buffer.set_lines(right_buf, diff_result.new_lines)

    local left_win, right_win
    if existing_wins and #existing_wins == 2 then
      left_win = existing_wins[1]
      right_win = existing_wins[2]
      -- Clear diffmode before swapping buffers
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

    return { left_buf, right_buf }, { left_win, right_win }
  else
    local inline = require("diffv.ui.inline")

    local buf = buffer.create(
      filetype,
      "diffv://" .. file_info.path .. " (" .. file_info.old_label .. " → " .. file_info.new_label .. ")"
    )
    buffer.set_lines(buf, diff_result.new_lines)

    local win
    if existing_wins and #existing_wins == 1 then
      win = existing_wins[1]
      vim.api.nvim_win_set_buf(win, buf)
    else
      win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, buf)
    end

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

--- Open a diff view.
--- Supports: :DiffV (working tree), :DiffV --cached (staged), :DiffV <commit>, :DiffV a..b
--- Shows a file list panel when multiple files are changed.
---@param args? string[] command arguments
---@param file_path? string specific file to diff (relative to repo root), skips filelist
function M.open(args, file_path)
  args = args or {}

  local git = require("diffv.git")
  local provider = require("diffv.git.provider")
  local diff_engine = require("diffv.diff")
  local ui = require("diffv.ui")
  local filelist = require("diffv.ui.filelist")
  local config = require("diffv.config").values

  local root = git.repo_root()
  if not root then
    vim.notify("diffv: not in a git repository", vim.log.levels.ERROR)
    return
  end

  -- Single file specified — open directly, no filelist
  if file_path then
    local filetype = vim.filetype.match({ filename = file_path }) or ""
    local old_text, new_text, old_label, new_label = resolve_file(args, file_path, root)
    old_text = old_text or ""
    new_text = new_text or ""

    if old_text == new_text then
      vim.notify("diffv: no differences in " .. file_path, vim.log.levels.INFO)
      return
    end

    local diff_result = diff_engine.diff(old_text, new_text)
    ui.create(diff_result, filetype, config, {
      path = file_path,
      old_label = old_label,
      new_label = new_label,
    })
    return
  end

  -- Multi-file: get all changed files
  local files, err = provider.changed_files_sync(args)
  if err or #files == 0 then
    vim.notify("diffv: no changes found", vim.log.levels.INFO)
    return
  end

  -- Single changed file — open directly, no filelist
  if #files == 1 then
    local rel_path = files[1].path
    local filetype = vim.filetype.match({ filename = rel_path }) or ""
    local old_text, new_text, old_label, new_label = resolve_file(args, rel_path, root)
    old_text = old_text or ""
    new_text = new_text or ""

    if old_text == new_text then
      vim.notify("diffv: no differences in " .. rel_path, vim.log.levels.INFO)
      return
    end

    local diff_result = diff_engine.diff(old_text, new_text)
    ui.create(diff_result, filetype, config, {
      path = rel_path,
      old_label = old_label,
      new_label = new_label,
    })
    return
  end

  -- Multiple files: filelist + in-place diff rendering
  if ui.active then
    ui.destroy()
  end

  local diff_bufs = {}
  local diff_wins = {}
  local current_layout = config.layout
  local current_file_index = 1
  local closing = false
  local augroup = vim.api.nvim_create_augroup("diffv_winguard", { clear = true })

  --- Tear down the entire view when any window is externally closed.
  local function setup_win_guards()
    vim.api.nvim_clear_autocmds({ group = augroup })

    -- Collect all windows that belong to this view
    local guard_wins = {}
    if filelist.state and vim.api.nvim_win_is_valid(filelist.state.win) then
      guard_wins[#guard_wins + 1] = filelist.state.win
    end
    for _, win in ipairs(diff_wins) do
      if vim.api.nvim_win_is_valid(win) then
        guard_wins[#guard_wins + 1] = win
      end
    end

    for _, win in ipairs(guard_wins) do
      vim.api.nvim_create_autocmd("WinClosed", {
        group = augroup,
        pattern = tostring(win),
        once = true,
        callback = function()
          if closing then
            return
          end
          closing = true
          vim.schedule(function()
            M.close()
          end)
        end,
      })
    end
  end

  --- Close diff windows and wipe diff buffers without touching the filelist.
  local function cleanup_diff()
    closing = true
    for _, win in ipairs(diff_wins) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
    for _, buf in ipairs(diff_bufs) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
    end
    diff_bufs = {}
    diff_wins = {}
    ui.active = nil
    closing = false
  end

  --- Check whether the current diff windows can be reused for the given layout.
  ---@param layout string
  ---@return boolean
  local function can_reuse_windows(layout)
    if layout == "side_by_side" then
      return #diff_wins == 2 and vim.api.nvim_win_is_valid(diff_wins[1]) and vim.api.nvim_win_is_valid(diff_wins[2])
    else
      return #diff_wins == 1 and vim.api.nvim_win_is_valid(diff_wins[1])
    end
  end

  --- Ensure diff windows exist to the right of the filelist.
  --- Creates them if missing, reuses if layout matches.
  ---@param layout string
  local function ensure_diff_windows(layout)
    if can_reuse_windows(layout) then
      -- Wipe old buffers but keep windows
      for i, buf in ipairs(diff_bufs) do
        if vim.api.nvim_buf_is_valid(buf) then
          -- Detach from window first so bufhidden=wipe doesn't close the window
          local placeholder = vim.api.nvim_create_buf(false, true)
          vim.bo[placeholder].bufhidden = "wipe"
          if diff_wins[i] and vim.api.nvim_win_is_valid(diff_wins[i]) then
            vim.api.nvim_win_set_buf(diff_wins[i], placeholder)
          end
          -- Buffer may already be wiped by bufhidden=wipe
          if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
          end
        end
      end
      diff_bufs = {}
      ui.active = nil
      return
    end

    -- Layout changed or windows gone — full cleanup + recreate
    filelist.save_width()
    cleanup_diff()

    if filelist.state and vim.api.nvim_win_is_valid(filelist.state.win) then
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

  --- Open a specific file from the list by index.
  ---@param index number
  local function open_file(index)
    local f = files[index]
    if not f then
      return
    end

    local rel_path = f.path
    local filetype = vim.filetype.match({ filename = rel_path }) or ""

    local old_text, new_text, old_label, new_label = resolve_file(args, rel_path, root)
    old_text = old_text or ""
    new_text = new_text or ""

    if old_text == new_text then
      vim.notify("diffv: no differences in " .. rel_path, vim.log.levels.INFO)
      return
    end

    local diff_result = diff_engine.diff(old_text, new_text)

    local reuse = can_reuse_windows(current_layout)
    ensure_diff_windows(current_layout)

    local file_info = {
      path = rel_path,
      old_label = old_label,
      new_label = new_label,
    }

    current_file_index = index
    local buffers, windows =
      render_diff_inplace(diff_result, filetype, config, file_info, current_layout, reuse and diff_wins or nil)

    diff_bufs = buffers
    diff_wins = windows

    ---@type diffv.DiffView
    local view = {
      buffers = buffers,
      windows = windows,
      tabnr = vim.fn.tabpagenr(),
      layout = current_layout,
      diff_result = diff_result,
      context_lines = config.context,
      filetype = filetype,
      file_info = file_info,
      file_changes = {},
      current_index = index,
      config = config,
      close = function()
        M.close()
      end,
    }

    view.toggle_layout_impl = function()
      if current_layout == "side_by_side" then
        current_layout = "inline"
      else
        current_layout = "side_by_side"
      end
      open_file(current_file_index)
    end

    ui.active = view
    ui.apply_context(view)

    local km = config.keymaps
    for _, buf in ipairs(buffers) do
      vim.keymap.set("n", km.close, function()
        M.close()
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

    filelist.set_current(index)
    setup_win_guards()
  end

  vim.cmd("tabnew")

  filelist.create(files, 1, function(index)
    open_file(index)
  end)

  open_file(1)
end

--- Open a commit with a persistent file list panel.
---@param rev string commit hash
function M.open_commit(rev)
  M.open({ rev })
end

--- Open an inline diff view (convenience wrapper).
---@param args? string[]
---@param file_path? string
function M.open_inline(args, file_path)
  local config = require("diffv.config")
  local saved_layout = config.values.layout
  config.values.layout = "inline"
  M.open(args, file_path)
  config.values.layout = saved_layout
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
