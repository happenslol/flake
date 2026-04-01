--- Layout manager for diffv views.
local M = {}

--- The currently active diff view, if any.
---@type diffv.DiffView?
M.active = nil

--- Create a new diff view.
---@param diff_result diffv.DiffResult
---@param filetype string
---@param config diffv.Config
---@param file_info? { path: string, old_label: string, new_label: string }
---@return diffv.DiffView
function M.create(diff_result, filetype, config, file_info)
  -- Close any existing view first
  if M.active then
    M.destroy()
  end

  local context = require("diffv.ui.context")
  local layout = config.layout
  local buffers, windows, tabnr

  if layout == "side_by_side" then
    buffers, windows, tabnr = require("diffv.ui.side_by_side").render(diff_result, filetype, config, file_info)
  else
    buffers, windows, tabnr = require("diffv.ui.inline").render(diff_result, filetype, config, file_info)
  end

  ---@type diffv.DiffView
  local view = {
    buffers = buffers,
    windows = windows,
    tabnr = tabnr,
    layout = layout,
    diff_result = diff_result,
    context_lines = config.context,
    filetype = filetype,
    file_info = file_info,
    file_changes = {},
    current_index = 1,
    config = config,
    close = function()
      M.destroy()
    end,
  }

  -- Toggle re-renders in place with the opposite layout
  view.toggle_layout = function()
    M.toggle_layout()
  end

  M.active = view

  -- Apply initial context folding
  M.apply_context(view)

  -- Set up keybinds
  local km = config.keymaps
  for _, buf in ipairs(buffers) do
    vim.keymap.set("n", km.increase_context, function()
      M.adjust_context(5)
    end, { buffer = buf, desc = "Increase diff context" })

    vim.keymap.set("n", km.decrease_context, function()
      M.adjust_context(-5)
    end, { buffer = buf, desc = "Decrease diff context" })

    vim.keymap.set("n", km.toggle_context, function()
      M.toggle_context()
    end, { buffer = buf, desc = "Toggle context folding" })

    vim.keymap.set("n", km.toggle_layout, function()
      M.toggle_layout()
    end, { buffer = buf, desc = "Toggle diff layout" })
  end

  return view
end

--- Apply context folding to the active view.
---@param view diffv.DiffView
function M.apply_context(view)
  local context = require("diffv.ui.context")

  if view.layout == "side_by_side" then
    context.apply_side_by_side(view.context_lines)
    -- Set up foldtext on both windows
    for _, win in ipairs(view.windows) do
      if vim.api.nvim_win_is_valid(win) then
        context.setup_foldtext(win)
      end
    end
  else
    -- Inline: apply manual folds
    for i, win in ipairs(view.windows) do
      if vim.api.nvim_win_is_valid(win) then
        local buf = view.buffers[i]
        local total = vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_line_count(buf) or 0
        context.apply_inline(win, view.diff_result.hunks, total, view.context_lines)
        context.setup_foldtext(win)
      end
    end
  end
end

--- Adjust context lines by a delta and reapply folding.
---@param delta number
function M.adjust_context(delta)
  if not M.active then
    return
  end
  local new_ctx = math.max(1, M.active.context_lines + delta)
  if new_ctx == M.active.context_lines then
    return
  end
  M.active.context_lines = new_ctx
  M.apply_context(M.active)
  vim.notify("diffv: context = " .. new_ctx .. " lines", vim.log.levels.INFO)
end

--- Toggle between current context folding and showing the entire file.
function M.toggle_context()
  if not M.active then
    return
  end
  if M.active.context_lines == 0 then
    M.active.context_lines = M.active._saved_context or M.active.config.context
    M.active._saved_context = nil
    M.apply_context(M.active)
    vim.notify("diffv: context = " .. M.active.context_lines .. " lines", vim.log.levels.INFO)
  else
    M.active._saved_context = M.active.context_lines
    M.active.context_lines = 0
    M.apply_context(M.active)
    vim.notify("diffv: showing entire file", vim.log.levels.INFO)
  end
end

--- Toggle between side_by_side and inline layout for the active view.
function M.toggle_layout()
  if not M.active then
    return
  end
  local view = M.active
  if view.toggle_layout_impl then
    -- Commit views provide their own implementation
    view.toggle_layout_impl()
    return
  end

  -- Standalone view: destroy and recreate with flipped layout
  local diff_result = view.diff_result
  local filetype = view.filetype
  local file_info = view.file_info
  local config = vim.deepcopy(view.config)
  local context_lines = view.context_lines

  M.destroy()

  if config.layout == "side_by_side" then
    config.layout = "inline"
  else
    config.layout = "side_by_side"
  end

  local new_view = M.create(diff_result, filetype, config, file_info)
  new_view.context_lines = context_lines
  M.apply_context(new_view)
end

--- Destroy the active diff view and clean up.
function M.destroy()
  if not M.active then
    return
  end

  local view = M.active
  M.active = nil

  -- Clear window guards
  pcall(vim.api.nvim_del_augroup_by_name, "diffv_winguard")

  -- Close file list panel if open
  local filelist = require("diffv.ui.filelist")
  filelist.destroy()

  -- Restore diffopt (remove our context setting)
  if view.layout == "side_by_side" then
    local opts = vim.opt.diffopt:get()
    local new_opts = {}
    for _, o in ipairs(opts) do
      if not o:match("^context:") then
        new_opts[#new_opts + 1] = o
      end
    end
    vim.opt.diffopt = new_opts
  end

  -- If we opened a tab, just close it — buffers auto-wipe (bufhidden=wipe)
  if view.tabnr and vim.fn.tabpagenr("$") > 1 then
    for _, win in ipairs(view.windows) do
      if vim.api.nvim_win_is_valid(win) then
        local win_tabnr = vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(win))
        vim.cmd(win_tabnr .. "tabclose")
        return
      end
    end
  end

  -- Fallback: close windows individually
  for _, win in ipairs(view.windows) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- Force-clean any remaining buffers
  for _, buf in ipairs(view.buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end

return M
