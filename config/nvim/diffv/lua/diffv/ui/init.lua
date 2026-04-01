--- UI helpers for the active diff view.
--- The ViewState (diffv.state) owns the lifecycle; this module provides
--- context folding and layout toggle that operate on the current view.
local M = {}

--- The currently active view info, set by ViewState:select_file().
---@type diffv.View?
M.active = nil

--- Apply context folding to a view.
---@param view table must have layout, context_lines, windows, buffers, diff_result
function M.apply_context(view)
  local context = require("diffv.ui.context")

  if view.layout == "side_by_side" then
    context.apply_side_by_side(view.context_lines)
    for _, win in ipairs(view.windows) do
      if vim.api.nvim_win_is_valid(win) then
        context.setup_foldtext(win)
      end
    end
  else
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

--- Toggle between side_by_side and inline layout.
function M.toggle_layout()
  if not M.active then
    return
  end
  if M.active.toggle_layout_impl then
    M.active.toggle_layout_impl()
  end
end

return M
