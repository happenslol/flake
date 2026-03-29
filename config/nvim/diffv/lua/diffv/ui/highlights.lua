--- Extmark-based highlight application for diff buffers.
local M = {}

--- Apply diff highlights to a buffer for one side of a side-by-side view.
--- Handles line-level (DiffAdd/DiffDelete/DiffChange) and word-level (DiffText) highlighting.
---@param buf number buffer handle
---@param line_map diffv.SideLine[] the line mapping for this side
---@param config diffv.Config
function M.apply_side(buf, line_map, config)
  local ns = require("diffv").ns()
  local hl = config.highlights
  local line_diff = require("diffv.diff.line")

  for i, entry in ipairs(line_map) do
    local row = i - 1 -- 0-indexed
    if entry.type == "add" then
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
        end_row = row + 1,
        hl_group = hl.add,
        hl_eol = true,
        priority = 10,
      })
    elseif entry.type == "delete" then
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
        end_row = row + 1,
        hl_group = hl.delete,
        hl_eol = true,
        priority = 10,
      })
    elseif entry.type == "change" then
      -- Line-level change highlight
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
        end_row = row + 1,
        hl_group = hl.change,
        hl_eol = true,
        priority = 10,
      })
      -- Word-level highlights within the changed line
      if entry.paired_content then
        local word_result
        if entry.side == "old" then
          word_result = line_diff.word_diff(entry.content, entry.paired_content)
          for _, range in ipairs(word_result.old_ranges) do
            local col_start = math.min(range[1], #entry.content)
            local col_end = math.min(range[2], #entry.content)
            if col_start < col_end then
              vim.api.nvim_buf_set_extmark(buf, ns, row, col_start, {
                end_row = row,
                end_col = col_end,
                hl_group = hl.change_text,
                priority = 20,
              })
            end
          end
        else
          word_result = line_diff.word_diff(entry.paired_content, entry.content)
          for _, range in ipairs(word_result.new_ranges) do
            local col_start = math.min(range[1], #entry.content)
            local col_end = math.min(range[2], #entry.content)
            if col_start < col_end then
              vim.api.nvim_buf_set_extmark(buf, ns, row, col_start, {
                end_row = row,
                end_col = col_end,
                hl_group = hl.change_text,
                priority = 20,
              })
            end
          end
        end
      end
    elseif entry.type == "padding" then
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
        end_row = row + 1,
        hl_group = "NonText",
        hl_eol = true,
        priority = 10,
      })
    end
  end
end

--- Clear all diffv highlights from a buffer.
---@param buf number buffer handle
function M.clear(buf)
  local ns = require("diffv").ns()
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

return M
