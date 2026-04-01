--- Context folding for diff views.
--- Hides unchanged lines beyond N lines from the nearest change.
--- Uses manual folds for inline view, diffopt for side-by-side.
local M = {}

--- Compute fold ranges for the inline view.
--- Returns a list of {start_line, end_line} (1-indexed) ranges to fold.
---@param hunks diffv.Hunk[]
---@param total_lines number total buffer lines
---@param context_lines number lines of context around changes (0 = show all)
---@return { [1]: number, [2]: number }[] fold_ranges
function M.compute_fold_ranges(hunks, total_lines, context_lines)
  if context_lines <= 0 or total_lines == 0 or #hunks == 0 then
    return {}
  end

  -- Collect all changed line ranges in the new file (1-indexed)
  local visible = {} -- set of line numbers that should be visible
  for _, hunk in ipairs(hunks) do
    -- Lines that have adds or changes are visible
    for _, line in ipairs(hunk.lines) do
      if line.type == "add" and line.new_lnum then
        -- Mark context around this line
        for l = math.max(1, line.new_lnum - context_lines), math.min(total_lines, line.new_lnum + context_lines) do
          visible[l] = true
        end
      end
    end
    -- Also mark context around the hunk boundary for pure deletes
    if hunk.new_start > 0 then
      for l = math.max(1, hunk.new_start - context_lines), math.min(total_lines, hunk.new_start + context_lines) do
        visible[l] = true
      end
    end
  end

  -- Build contiguous fold ranges from non-visible lines
  local ranges = {}
  local fold_start = nil

  for lnum = 1, total_lines do
    if not visible[lnum] then
      if not fold_start then
        fold_start = lnum
      end
    else
      if fold_start then
        ranges[#ranges + 1] = { fold_start, lnum - 1 }
        fold_start = nil
      end
    end
  end
  if fold_start then
    ranges[#ranges + 1] = { fold_start, total_lines }
  end

  return ranges
end

--- Apply manual folds to a buffer in a specific window.
---@param win number window handle
---@param fold_ranges { [1]: number, [2]: number }[]
function M.apply_folds(win, fold_ranges)
  vim.api.nvim_win_call(win, function()
    -- Clear existing folds
    vim.cmd("normal! zE")
    -- Create new folds (bottom-up to avoid line shifts)
    for i = #fold_ranges, 1, -1 do
      local range = fold_ranges[i]
      vim.cmd(range[1] .. "," .. range[2] .. "fold")
    end
  end)
end

--- Apply context folding for the inline view.
---@param win number window handle
---@param hunks diffv.Hunk[]
---@param total_lines number
---@param context_lines number
function M.apply_inline(win, hunks, total_lines, context_lines)
  if context_lines <= 0 then
    -- Show all: open all folds
    vim.api.nvim_win_call(win, function()
      vim.cmd("normal! zE")
    end)
    return
  end

  local ranges = M.compute_fold_ranges(hunks, total_lines, context_lines)
  M.apply_folds(win, ranges)
end

--- Apply context for side-by-side view via diffopt.
---@param context_lines number
function M.apply_side_by_side(context_lines)
  if context_lines <= 0 then
    -- Show all: set a very large context
    vim.opt.diffopt:append("context:99999")
  else
    -- Remove any existing context setting and add the new one
    local opts = vim.opt.diffopt:get()
    local new_opts = {}
    for _, o in ipairs(opts) do
      if not o:match("^context:") then
        new_opts[#new_opts + 1] = o
      end
    end
    new_opts[#new_opts + 1] = "context:" .. context_lines
    vim.opt.diffopt = new_opts
  end
end

--- Set up a custom foldtext for diffv buffers.
---@param win number
function M.setup_foldtext(win)
  vim.wo[win].foldtext = "v:lua.require'diffv.ui.context'.foldtext()"
  vim.wo[win].foldminlines = 1
end

--- Custom foldtext function showing the number of hidden lines.
---@return string
function M.foldtext()
  local start = vim.v.foldstart
  local finish = vim.v.foldend
  local count = finish - start + 1
  return "  ··· " .. count .. " lines ···"
end

return M
