--- Inline (single-buffer) overlay diff renderer.
--- Shows the new version with syntax highlighting.
--- Deleted/changed old lines shown as virtual lines above with treesitter highlighting.
--- Added/changed new lines highlighted in place.
--- Left (old) side always red, right (new) side always green.
local M = {}

--- Extract treesitter highlights for old (deleted) lines and cache them.
--- Creates a temporary buffer, lets treesitter parse it, extracts highlights.
---@param old_lines string[] full old file content
---@param filetype string
---@return table<number, {col_start: number, col_end: number, hl_group: string}[]> highlights keyed by 0-indexed row
local function extract_old_highlights(old_lines, filetype)
  if not filetype or filetype == "" or #old_lines == 0 then
    return {}
  end

  local ts = require("diffv.treesitter")
  local hl_buf = ts.create_highlight_buf(old_lines, filetype)
  local highlights = ts.get_highlights(hl_buf, 0, #old_lines)

  -- Wipe the temporary buffer
  vim.api.nvim_buf_delete(hl_buf, { force = true })

  return highlights
end

--- Build a syntax-highlighted virt_line for a deleted/old line.
---@param text string line content
---@param row number 0-indexed row in old file
---@param old_hl table<number, table[]> old file highlights
---@param base_hl string base highlight for the diff (e.g. DiffvMinusBg)
---@param emph_hl string emphasis highlight for word changes (e.g. DiffvMinusEmph)
---@param emph_ranges? number[][] word-diff emphasis ranges
---@return {[1]: string, [2]: string}[] virt_line chunks
local function build_highlighted_virt_line(text, row, old_hl, base_hl, emph_hl, emph_ranges)
  local ts = require("diffv.treesitter")
  local highlights = old_hl[row]
  return ts.build_virt_line(text, highlights, base_hl, emph_hl, emph_ranges)
end

--- Apply inline diff overlay to a buffer that contains the new file content.
--- Can be used standalone (for the inline view) or on any buffer (for picker preview).
---@param buf number buffer handle (must already contain new_lines content)
---@param diff_result diffv.DiffResult
---@param config diffv.Config
---@param filetype? string filetype for syntax highlighting of old lines
function M.apply_overlay(buf, diff_result, config, filetype)
  local ns = require("diffv").ns()
  local hl = config.highlights
  local line_diff = require("diffv.diff.line")

  -- Extract treesitter highlights for old file content
  local old_hl = extract_old_highlights(diff_result.old_lines, filetype)

  -- Word-level emphasis threshold: >60% similarity = distance < 0.4
  local word_highlight_max_distance = 0.4

  for _, hunk in ipairs(diff_result.hunks) do
    local deletes = {}
    local adds = {}

    for _, line in ipairs(hunk.lines) do
      if line.type == "delete" then
        deletes[#deletes + 1] = line
      elseif line.type == "add" then
        adds[#adds + 1] = line
      end
    end

    -- Pair deletes with adds, but only if lines are similar enough.
    local max_distance = 0.6
    local paired = math.min(#deletes, #adds)
    local actually_paired = 0

    for i = 1, paired do
      local dist = line_diff.line_distance(deletes[i].content, adds[i].content)
      if dist <= max_distance then
        actually_paired = i
      else
        break
      end
    end

    -- Paired changes (delete + add = change with word-level diff)
    for i = 1, actually_paired do
      local del = deletes[i]
      local add = adds[i]
      local buf_row = add.new_lnum - 1
      local dist = line_diff.line_distance(del.content, add.content)

      -- Highlight the buffer line (new version) with green bg
      vim.api.nvim_buf_set_extmark(buf, ns, buf_row, 0, {
        end_row = buf_row + 1,
        hl_group = hl.plus,
        hl_eol = true,
        priority = 100,
        number_hl_group = hl.plus_nr,
      })

      -- Compute word-level diff for emphasis and virtual line
      local word_result = line_diff.word_diff(del.content, add.content)
      local show_word_emphasis = dist <= word_highlight_max_distance

      -- Word-level highlights on the buffer line (brighter green on changed words)
      if show_word_emphasis then
        for _, range in ipairs(word_result.new_ranges) do
          local col_start = math.min(range[1], #add.content)
          local col_end = math.min(range[2], #add.content)
          if col_start < col_end then
            vim.api.nvim_buf_set_extmark(buf, ns, buf_row, col_start, {
              end_row = buf_row,
              end_col = col_end,
              hl_group = hl.plus_emph,
              priority = 200,
            })
          end
        end
      end

      -- Show old version as virtual line above (red bg, brighter red on changed words)
      local old_row = del.old_lnum - 1
      local emph_ranges = show_word_emphasis and word_result.old_ranges or nil
      local virt_chunks =
        build_highlighted_virt_line(del.content, old_row, old_hl, hl.minus, hl.minus_emph, emph_ranges)
      vim.api.nvim_buf_set_extmark(buf, ns, buf_row, 0, {
        virt_lines = { virt_chunks },
        virt_lines_above = true,
      })
    end

    -- Remaining unpaired adds (too different or extra adds) — green bg
    for i = actually_paired + 1, #adds do
      local add = adds[i]
      local buf_row = add.new_lnum - 1
      vim.api.nvim_buf_set_extmark(buf, ns, buf_row, 0, {
        end_row = buf_row + 1,
        hl_group = hl.plus,
        hl_eol = true,
        priority = 100,
        number_hl_group = hl.plus_nr,
      })
    end

    -- Remaining unpaired deletes (too different or extra deletes) — red bg virtual lines
    local unpaired_del_virt = {}
    for i = actually_paired + 1, #deletes do
      local del = deletes[i]
      local old_row = del.old_lnum - 1
      unpaired_del_virt[#unpaired_del_virt + 1] =
        build_highlighted_virt_line(del.content, old_row, old_hl, hl.minus, hl.minus, nil)
    end
    if #unpaired_del_virt > 0 then
      -- Anchor: if there are unpaired adds after, attach above the first one;
      -- otherwise attach at the hunk boundary in the new file
      local anchor_row
      if actually_paired < #adds then
        anchor_row = adds[actually_paired + 1].new_lnum - 1
      else
        anchor_row = math.max(0, hunk.new_start - 1)
      end
      vim.api.nvim_buf_set_extmark(buf, ns, anchor_row, 0, {
        virt_lines = unpaired_del_virt,
        virt_lines_above = true,
      })
    end
  end
end

--- Render an inline diff view in a new tab.
---@param diff_result diffv.DiffResult
---@param filetype string filetype for syntax highlighting
---@param config diffv.Config
---@param file_info? { path: string, old_label: string, new_label: string }
---@return number[] buffers
---@return number[] windows
---@return number tabnr
function M.render(diff_result, filetype, config, file_info)
  local buffer = require("diffv.buffer")

  local path = file_info and file_info.path or "unknown"
  local old_label = file_info and file_info.old_label or "old"
  local new_label = file_info and file_info.new_label or "new"

  local buf = buffer.create(filetype, "diffv://" .. path .. " (" .. old_label .. " → " .. new_label .. ")")
  buffer.set_lines(buf, diff_result.new_lines)

  vim.cmd("tabnew")
  local tabnr = vim.fn.tabpagenr()
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  vim.wo[win].number = true
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  vim.wo[win].foldmethod = "manual"
  vim.wo[win].foldlevel = 0

  M.apply_overlay(buf, diff_result, config, filetype)

  -- Close keybind
  vim.keymap.set("n", config.keymaps.close, function()
    require("diffv").close()
  end, { buffer = buf, desc = "Close diffv" })

  return { buf }, { win }, tabnr
end

return M
