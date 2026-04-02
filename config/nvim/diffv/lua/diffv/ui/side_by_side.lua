--- Side-by-side diff renderer.
--- Uses vim's built-in diff mode for filler lines, scrollbind, and alignment.
--- Custom highlight groups (via winhighlight) give red on left, green on right.
--- Word-level extmark highlights for lines with >60% similarity.
local M = {}

--- Apply winhighlight to redirect vim's Diff* groups to our custom groups.
---@param left_win number
---@param right_win number
---@param config diffv.Config
function M.set_winhighlight(left_win, right_win, config)
  local hl = config.highlights
  -- Left window: all diff highlighting is red (minus)
  -- DiffText maps to same as DiffChange so vim's built-in word highlight is invisible
  vim.wo[left_win].winhighlight = table.concat({
    "DiffAdd:" .. hl.minus,
    "DiffChange:" .. hl.minus,
    "DiffText:" .. hl.minus,
    "DiffDelete:" .. hl.filler,
  }, ",")
  -- Right window: all diff highlighting is green (plus)
  vim.wo[right_win].winhighlight = table.concat({
    "DiffAdd:" .. hl.plus,
    "DiffChange:" .. hl.plus,
    "DiffText:" .. hl.plus,
    "DiffDelete:" .. hl.filler,
  }, ",")
end

--- Find paired changed lines from a diff result for word-level highlighting.
--- Only pairs lines that are similar enough (distance <= 0.6).
---@param diff_result diffv.DiffResult
---@return { old_lnum: number, new_lnum: number, old_content: string, new_content: string, distance: number }[]
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
          distance = dist,
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

--- Collect line numbers that have diff highlighting, for number_hl_group.
---@param diff_result diffv.DiffResult
---@return table<number, true> old_lnums (1-indexed) that are deleted or changed
---@return table<number, true> new_lnums (1-indexed) that are added or changed
local function collect_highlighted_lines(diff_result)
  local old_set = {}
  local new_set = {}

  for _, hunk in ipairs(diff_result.hunks) do
    for _, line in ipairs(hunk.lines) do
      if line.type == "delete" then
        old_set[line.old_lnum] = true
      elseif line.type == "add" then
        new_set[line.new_lnum] = true
      end
    end
  end

  return old_set, new_set
end

--- Apply word-level and number highlights on both buffers.
---@param left_buf number
---@param right_buf number
---@param diff_result diffv.DiffResult
---@param config diffv.Config
function M.apply_highlights(left_buf, right_buf, diff_result, config)
  local ns = require("diffv").ns()
  local hl = config.highlights
  local line_diff = require("diffv.diff.line")

  -- Number highlighting for all changed/added/deleted lines
  local old_set, new_set = collect_highlighted_lines(diff_result)

  for lnum in pairs(old_set) do
    local row = lnum - 1
    vim.api.nvim_buf_set_extmark(left_buf, ns, row, 0, {
      number_hl_group = hl.minus_nr,
      priority = 10,
    })
  end

  for lnum in pairs(new_set) do
    local row = lnum - 1
    vim.api.nvim_buf_set_extmark(right_buf, ns, row, 0, {
      number_hl_group = hl.plus_nr,
      priority = 10,
    })
  end

  -- Word-level emphasis only for paired lines with >60% similarity (distance < 0.4)
  local change_pairs = find_change_pairs(diff_result)
  local word_highlight_max_distance = 0.4

  for _, pair in ipairs(change_pairs) do
    if pair.distance <= word_highlight_max_distance then
      local result = line_diff.word_diff(pair.old_content, pair.new_content)

      -- Old side (left buffer) — brighter red on changed words
      local old_row = pair.old_lnum - 1
      for _, range in ipairs(result.old_ranges) do
        local col_start = math.min(range[1], #pair.old_content)
        local col_end = math.min(range[2], #pair.old_content)
        if col_start < col_end then
          vim.api.nvim_buf_set_extmark(left_buf, ns, old_row, col_start, {
            end_row = old_row,
            end_col = col_end,
            hl_group = hl.minus_emph,
            priority = 200,
          })
        end
      end

      -- New side (right buffer) — brighter green on changed words
      local new_row = pair.new_lnum - 1
      for _, range in ipairs(result.new_ranges) do
        local col_start = math.min(range[1], #pair.new_content)
        local col_end = math.min(range[2], #pair.new_content)
        if col_start < col_end then
          vim.api.nvim_buf_set_extmark(right_buf, ns, new_row, col_start, {
            end_row = new_row,
            end_col = col_end,
            hl_group = hl.plus_emph,
            priority = 200,
          })
        end
      end
    end
  end
end

return M
