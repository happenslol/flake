--- Treesitter integration for diffv.
--- Extracts highlights from treesitter on hidden buffers
--- and builds styled virtual line chunks.
local M = {}

--- Cache for dimmed highlight groups: dim_hl_cache[opacity][hl_group] = dimmed_group_name
local dim_hl_cache = {}

--- Blend two RGB integers.
---@param fg number
---@param bg number
---@param alpha number 0-1, where 0 = fully bg, 1 = fully fg
---@return number
local function blend_channel(fg, bg, alpha)
  return math.floor(fg * alpha + bg * (1 - alpha) + 0.5)
end

--- Get a dimmed version of a highlight group, creating it dynamically if needed.
--- Blends the fg color toward the background at the given opacity.
---@param hl_group string original highlight group
---@param opacity number 0-1, where 1 = full color, 0 = invisible
---@param bg_hex? string background color hex (defaults to Normal bg)
---@return string dimmed_group_name
function M.dim_hl(hl_group, opacity, bg_hex)
  -- Quantize opacity to avoid creating too many groups
  local key = math.floor(opacity * 100 + 0.5)
  if not dim_hl_cache[key] then
    dim_hl_cache[key] = {}
  end
  if dim_hl_cache[key][hl_group] then
    return dim_hl_cache[key][hl_group]
  end

  -- Resolve the original highlight's fg color (follow links)
  local hl_info = vim.api.nvim_get_hl(0, { name = hl_group, link = false })
  local fg = hl_info.fg

  if not fg then
    -- No fg color — just return the original
    dim_hl_cache[key][hl_group] = hl_group
    return hl_group
  end

  -- Get background color
  local bg
  if bg_hex then
    bg = tonumber(bg_hex:sub(2), 16)
  else
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    bg = normal.bg or 0x212121
  end

  -- Blend fg toward bg
  local fg_r, fg_g, fg_b = bit.rshift(fg, 16), bit.band(bit.rshift(fg, 8), 0xff), bit.band(fg, 0xff)
  local bg_r, bg_g, bg_b = bit.rshift(bg, 16), bit.band(bit.rshift(bg, 8), 0xff), bit.band(bg, 0xff)

  local r = blend_channel(fg_r, bg_r, opacity)
  local g = blend_channel(fg_g, bg_g, opacity)
  local b = blend_channel(fg_b, bg_b, opacity)

  local dimmed_name = string.format("DiffvDim%d_%s", key, hl_group:gsub("[%.@]", "_"))
  vim.api.nvim_set_hl(0, dimmed_name, {
    fg = string.format("#%02x%02x%02x", r, g, b),
    bg = hl_info.bg and string.format("#%02x%02x%02x",
      bit.rshift(hl_info.bg, 16),
      bit.band(bit.rshift(hl_info.bg, 8), 0xff),
      bit.band(hl_info.bg, 0xff)) or nil,
    italic = hl_info.italic,
    bold = hl_info.bold,
  })

  dim_hl_cache[key][hl_group] = dimmed_name
  return dimmed_name
end

--- Clear the dimmed highlight cache (call on theme reload).
function M.clear_dim_cache()
  dim_hl_cache = {}
end

--- Extract treesitter highlights for specific lines from a buffer.
--- Returns a table keyed by 0-indexed row, each value is a sorted list
--- of {col_start, col_end, hl_group}.
---@param buf number buffer with content and filetype set
---@param start_row number 0-indexed start row
---@param end_row number 0-indexed end row (exclusive)
---@return table<number, {col_start: number, col_end: number, hl_group: string}[]>
function M.get_highlights(buf, start_row, end_row)
  local ft = vim.bo[buf].filetype
  if not ft or ft == "" then
    return {}
  end

  -- Resolve filetype to treesitter language
  local lang = vim.treesitter.language.get_lang(ft) or ft
  local ok = pcall(vim.treesitter.language.add, lang)
  if not ok then
    return {}
  end

  local parser = vim.treesitter.get_parser(buf, lang)
  if not parser then
    return {}
  end

  parser:parse()

  local query = vim.treesitter.query.get(lang, "highlights")
  if not query then
    return {}
  end

  local result = {}

  for id, node, _, _ in query:iter_captures(parser:trees()[1]:root(), buf, start_row, end_row) do
    local name = "@" .. query.captures[id]
    local sr, sc, er, ec = node:range()

    -- Resolve the highlight group name (treesitter captures use @name)
    local hl_group = name
    -- Check if a specific hl group exists for this lang, e.g. @keyword.lua
    local lang_hl = name .. "." .. lang
    if vim.fn.hlexists(lang_hl) == 1 then
      hl_group = lang_hl
    end

    -- Handle multi-line nodes: split into per-line segments
    for row = math.max(sr, start_row), math.min(er, end_row - 1) do
      if not result[row] then
        result[row] = {}
      end
      local c_start = (row == sr) and sc or 0
      local c_end
      if row == er then
        c_end = ec
      else
        -- End of this line
        local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
        c_end = line and #line or 0
      end
      if c_start < c_end then
        result[row][#result[row] + 1] = {
          col_start = c_start,
          col_end = c_end,
          hl_group = hl_group,
        }
      end
    end
  end

  -- Sort each row's highlights by col_start
  for _, highlights in pairs(result) do
    table.sort(highlights, function(a, b)
      return a.col_start < b.col_start
    end)
  end

  return result
end

--- Build a virt_lines chunk list for a single line with treesitter highlights.
--- Syntax highlights are dimmed to visually distinguish old/deleted lines.
--- Falls back to a single unhighlighted chunk if no highlights available.
---@param text string the line text
---@param highlights? {col_start: number, col_end: number, hl_group: string}[] sorted highlights
---@param base_hl? string base highlight group to apply to unhighlighted regions
---@param dim_opacity? number opacity for syntax colors (0-1, default 0.5)
---@return {[1]: string, [2]: string}[] chunks for virt_lines
function M.build_virt_line(text, highlights, base_hl, dim_opacity)
  dim_opacity = dim_opacity or 0.5

  if not highlights or #highlights == 0 then
    return { { text, base_hl and M.dim_hl(base_hl, dim_opacity) or "Normal" } }
  end

  local chunks = {}
  local pos = 0
  local dimmed_base = base_hl and M.dim_hl(base_hl, dim_opacity) or nil

  for _, hl in ipairs(highlights) do
    -- Gap before this highlight
    if hl.col_start > pos then
      local gap_text = text:sub(pos + 1, hl.col_start)
      if #gap_text > 0 then
        chunks[#chunks + 1] = { gap_text, dimmed_base }
      end
    end

    -- Highlighted segment — dimmed
    local seg_start = math.max(hl.col_start, pos)
    local seg_text = text:sub(seg_start + 1, hl.col_end)
    if #seg_text > 0 then
      chunks[#chunks + 1] = { seg_text, M.dim_hl(hl.hl_group, dim_opacity) }
    end

    pos = math.max(pos, hl.col_end)
  end

  -- Trailing text after last highlight
  if pos < #text then
    local trailing = text:sub(pos + 1)
    if #trailing > 0 then
      chunks[#chunks + 1] = { trailing, dimmed_base }
    end
  end

  -- Ensure at least one chunk (empty line case)
  if #chunks == 0 then
    chunks[#chunks + 1] = { text, dimmed_base or "Normal" }
  end

  return chunks
end

--- Create a hidden scratch buffer with content and filetype for highlight extraction.
--- The buffer is not listed and will be wiped after use.
---@param lines string[] content lines
---@param filetype string
---@return number buf
function M.create_highlight_buf(lines, filetype)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  if filetype and filetype ~= "" then
    vim.bo[buf].filetype = filetype
  end
  return buf
end

--- Merge highlights from two file versions onto a buffer with conflict markers.
---@param buf number buffer handle
---@param ours_highlights table[] highlights for "ours" version
---@param theirs_highlights table[] highlights for "theirs" version
---@param marker_map table mapping from buffer lines to version lines
function M.apply_merged_highlights(buf, ours_highlights, theirs_highlights, marker_map)
  vim.notify("diffv: treesitter.apply_merged_highlights() not yet implemented", vim.log.levels.INFO)
end

return M
