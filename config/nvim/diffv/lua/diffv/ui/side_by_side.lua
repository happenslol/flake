--- Side-by-side diff renderer.
--- Uses vim's built-in diff mode for filler lines, scrollbind, and line numbers.
--- Overlays word-level extmark highlights for finer granularity than vim's DiffText.
local M = {}

--- Set window-local options for a diff pane.
---@param win number window handle
local function set_win_opts(win)
  vim.wo[win].foldmethod = "diff"
  vim.wo[win].foldlevel = 0 -- start with context folds closed
  vim.wo[win].number = true
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
end

--- Find paired changed lines from a diff result for word-level highlighting.
--- Only pairs lines that are similar enough (distance <= 0.6, like delta).
---@param diff_result diffv.DiffResult
---@return { old_lnum: number, new_lnum: number, old_content: string, new_content: string }[]
local function find_change_pairs(diff_result)
  local line_diff = require("diffv.diff.line")
  local max_distance = 0.6
  local pairs = {}

  local function flush(deletes, adds)
    local n = math.min(#deletes, #adds)
    for i = 1, n do
      local dist = line_diff.line_distance(deletes[i].content, adds[i].content)
      if dist <= max_distance then
        pairs[#pairs + 1] = {
          old_lnum = deletes[i].old_lnum,
          new_lnum = adds[i].new_lnum,
          old_content = deletes[i].content,
          new_content = adds[i].content,
        }
      end
    end
  end

  for _, hunk in ipairs(diff_result.hunks) do
    local deletes = {}
    local adds = {}

    for _, line in ipairs(hunk.lines) do
      if line.type == "delete" then
        deletes[#deletes + 1] = line
      elseif line.type == "add" then
        adds[#adds + 1] = line
      elseif line.type == "context" then
        flush(deletes, adds)
        deletes = {}
        adds = {}
      end
    end

    flush(deletes, adds)
  end

  return pairs
end

--- Apply word-level DiffText highlights on paired changed lines.
---@param left_buf number
---@param right_buf number
---@param change_pairs { old_lnum: number, new_lnum: number, old_content: string, new_content: string }[]
---@param config diffv.Config
local function apply_word_highlights(left_buf, right_buf, change_pairs, config)
  local ns = require("diffv").ns()
  local hl = config.highlights
  local line_diff = require("diffv.diff.line")

  for _, pair in ipairs(change_pairs) do
    local result = line_diff.word_diff(pair.old_content, pair.new_content)

    -- Old side (left buffer)
    local old_row = pair.old_lnum - 1
    for _, range in ipairs(result.old_ranges) do
      local col_start = math.min(range[1], #pair.old_content)
      local col_end = math.min(range[2], #pair.old_content)
      if col_start < col_end then
        vim.api.nvim_buf_set_extmark(left_buf, ns, old_row, col_start, {
          end_row = old_row,
          end_col = col_end,
          hl_group = hl.change_text,
          priority = 200,
        })
      end
    end

    -- New side (right buffer)
    local new_row = pair.new_lnum - 1
    for _, range in ipairs(result.new_ranges) do
      local col_start = math.min(range[1], #pair.new_content)
      local col_end = math.min(range[2], #pair.new_content)
      if col_start < col_end then
        vim.api.nvim_buf_set_extmark(right_buf, ns, new_row, col_start, {
          end_row = new_row,
          end_col = col_end,
          hl_group = hl.change_text,
          priority = 200,
        })
      end
    end
  end
end

--- Apply word-level highlights to a pair of already-rendered diff buffers.
---@param left_buf number
---@param right_buf number
---@param diff_result diffv.DiffResult
---@param config diffv.Config
function M.apply_highlights(left_buf, right_buf, diff_result, config)
  local change_pairs = find_change_pairs(diff_result)
  apply_word_highlights(left_buf, right_buf, change_pairs, config)
end

--- Render a side-by-side diff view.
---@param diff_result diffv.DiffResult
---@param filetype string filetype for syntax highlighting
---@param config diffv.Config
---@param file_info? { path: string, old_label: string, new_label: string }
---@return number[] buffers created buffer handles
---@return number[] windows created window handles
---@return number tabnr tab page number
function M.render(diff_result, filetype, config, file_info)
  local buffer = require("diffv.buffer")

  local path = file_info and file_info.path or "unknown"
  local old_label = file_info and file_info.old_label or "old"
  local new_label = file_info and file_info.new_label or "new"

  -- Create buffers with the full file content (no padding needed)
  local left_buf = buffer.create(filetype, "diffv://" .. path .. " (" .. old_label .. ")")
  local right_buf = buffer.create(filetype, "diffv://" .. path .. " (" .. new_label .. ")")

  buffer.set_lines(left_buf, diff_result.old_lines)
  buffer.set_lines(right_buf, diff_result.new_lines)

  -- Create layout: new tab with vertical split
  vim.cmd("tabnew")
  local tabnr = vim.fn.tabpagenr()

  local left_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(left_win, left_buf)

  vim.cmd("vsplit")
  local right_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(right_win, right_buf)

  -- Enable vim's built-in diff mode on both windows
  -- This gives us: filler lines, scrollbind, cursorbind, correct line numbers,
  -- and base DiffAdd/DiffDelete/DiffChange highlighting for free.
  vim.api.nvim_win_call(left_win, function()
    vim.cmd("diffthis")
  end)
  vim.api.nvim_win_call(right_win, function()
    vim.cmd("diffthis")
  end)

  set_win_opts(left_win)
  set_win_opts(right_win)

  -- Overlay word-level highlights (higher priority than vim's built-in DiffText)
  local change_pairs = find_change_pairs(diff_result)
  apply_word_highlights(left_buf, right_buf, change_pairs, config)

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
