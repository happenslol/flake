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

  local layout = config.layout
  local buffers, windows, tabnr

  if layout == "side_by_side" then
    buffers, windows, tabnr = require("diffv.ui.side_by_side").render(diff_result, filetype, config, file_info)
  else
    buffers, windows = require("diffv.ui.inline").render(diff_result, filetype)
  end

  ---@type diffv.DiffView
  local view = {
    buffers = buffers,
    windows = windows,
    tabnr = tabnr,
    file_changes = {},
    current_index = 1,
    config = config,
    close = function()
      M.destroy()
    end,
  }

  M.active = view
  return view
end

--- Destroy the active diff view and clean up.
function M.destroy()
  if not M.active then
    return
  end

  local view = M.active
  M.active = nil

  -- If we opened a tab, just close it — buffers auto-wipe (bufhidden=wipe)
  if view.tabnr and vim.fn.tabpagenr("$") > 1 then
    -- Find the tab by checking if our windows are still in it
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
