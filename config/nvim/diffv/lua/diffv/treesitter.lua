--- Treesitter integration for diffv.
--- Extracts highlights from treesitter on hidden buffers
--- and builds styled virtual line chunks.
local M = {}

--- Cache for dynamically created highlight groups.
--- Key format: "opacity:bg_hl:fg_hl" → created group name
local hl_cache = {}

--- Blend two RGB integers.
local function blend_channel(fg, bg, alpha)
  return math.floor(fg * alpha + bg * (1 - alpha) + 0.5)
end

--- Resolve a highlight group's bg color as an integer.
---@param hl_name string
---@return number?
local function resolve_bg(hl_name)
  local info = vim.api.nvim_get_hl(0, { name = hl_name, link = false })
  return info.bg
end

--- Get the Normal bg as fallback.
---@return number
local function normal_bg()
  local info = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  return info.bg or 0x212121
end

--- Format an integer color as hex string.
---@param c number
---@return string
local function to_hex(c)
  return string.format("#%02x%02x%02x", bit.rshift(c, 16), bit.band(bit.rshift(c, 8), 0xff), bit.band(c, 0xff))
end

--- Compute an emphasized version of a diff bg highlight.
--- Brightens the bg color by scaling its channels.
---@param hl_name string highlight group name (e.g. "DiffDelete")
---@param factor? number brightening factor (default 2.5)
---@return string created highlight group name
function M.make_emph_hl(hl_name, factor)
  factor = factor or 2.5
  local cache_key = "emph:" .. hl_name .. ":" .. tostring(factor)
  if hl_cache[cache_key] then
    return hl_cache[cache_key]
  end

  local bg = resolve_bg(hl_name)
  if not bg then
    hl_cache[cache_key] = hl_name
    return hl_name
  end

  local r = math.min(255, math.floor(bit.rshift(bg, 16) * factor))
  local g = math.min(255, math.floor(bit.band(bit.rshift(bg, 8), 0xff) * factor))
  local b = math.min(255, math.floor(bit.band(bg, 0xff) * factor))

  local name = "DiffvEmph_" .. hl_name
  vim.api.nvim_set_hl(0, name, { bg = string.format("#%02x%02x%02x", r, g, b) })
  hl_cache[cache_key] = name
  return name
end

--- Create a highlight group with dimmed fg and a specific diff bg.
--- The fg is blended toward Normal bg at the given opacity.
--- The bg comes from a diff highlight group (e.g. DiffDelete, DiffDeleteText).
---@param fg_hl string source highlight group for fg color
---@param opacity number 0-1 for fg dimming
---@param bg_hl string highlight group to take bg from
---@return string created highlight group name
function M.make_hl(fg_hl, opacity, bg_hl)
  local key_opacity = math.floor(opacity * 100 + 0.5)
  local cache_key = key_opacity .. ":" .. bg_hl .. ":" .. fg_hl
  if hl_cache[cache_key] then
    return hl_cache[cache_key]
  end

  local hl_info = vim.api.nvim_get_hl(0, { name = fg_hl, link = false })
  local fg = hl_info.fg

  -- Resolve bg from the diff highlight group
  local diff_bg = resolve_bg(bg_hl)

  if not fg then
    -- No fg — create group with just the diff bg
    if diff_bg then
      local name = string.format("Diffv_%s_%s", bg_hl, fg_hl:gsub("[%.@]", "_"))
      vim.api.nvim_set_hl(0, name, { bg = to_hex(diff_bg) })
      hl_cache[cache_key] = name
      return name
    end
    hl_cache[cache_key] = bg_hl
    return bg_hl
  end

  -- Blend fg toward Normal bg
  local nbg = normal_bg()
  local fg_r, fg_g, fg_b = bit.rshift(fg, 16), bit.band(bit.rshift(fg, 8), 0xff), bit.band(fg, 0xff)
  local bg_r, bg_g, bg_b = bit.rshift(nbg, 16), bit.band(bit.rshift(nbg, 8), 0xff), bit.band(nbg, 0xff)

  local r = blend_channel(fg_r, bg_r, opacity)
  local g = blend_channel(fg_g, bg_g, opacity)
  local b = blend_channel(fg_b, bg_b, opacity)

  local name = string.format("Diffv%d_%s_%s", key_opacity, bg_hl, fg_hl:gsub("[%.@]", "_"))
  vim.api.nvim_set_hl(0, name, {
    fg = string.format("#%02x%02x%02x", r, g, b),
    bg = diff_bg and to_hex(diff_bg) or nil,
    italic = hl_info.italic,
    bold = hl_info.bold,
  })

  hl_cache[cache_key] = name
  return name
end

--- Clear the highlight cache (called on theme reload via module unload).
function M.clear_cache()
  hl_cache = {}
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

--- Check if a column position falls inside any emphasis range.
---@param col number 0-indexed column
---@param ranges number[][] list of {start, end} ranges (0-indexed, end-exclusive)
---@return boolean
local function in_emphasis(col, ranges)
  for _, r in ipairs(ranges) do
    if col >= r[1] and col < r[2] then
      return true
    end
  end
  return false
end

--- Build a virt_lines chunk list for a single line with treesitter highlights.
--- Syntax highlights are dimmed. Word-diff emphasis ranges get a brighter bg.
---@param text string the line text
---@param highlights? {col_start: number, col_end: number, hl_group: string}[] sorted highlights
---@param base_hl string diff bg highlight group (e.g. "DiffDelete")
---@param emph_hl string emphasis bg highlight group (e.g. "DiffDeleteText")
---@param emph_ranges? number[][] word-diff emphasis ranges {start, end}[]
---@param dim_opacity? number opacity for syntax fg (0-1, default 0.5)
---@return {[1]: string, [2]: string}[] chunks for virt_lines
function M.build_virt_line(text, highlights, base_hl, emph_hl, emph_ranges, dim_opacity)
  dim_opacity = dim_opacity or 0.5
  emph_ranges = emph_ranges or {}

  -- Helper: get the right hl group for a position (dimmed fg + correct bg)
  local function hl_at(fg_hl, col)
    local bg = in_emphasis(col, emph_ranges) and emph_hl or base_hl
    if fg_hl then
      return M.make_hl(fg_hl, dim_opacity, bg)
    else
      return M.make_hl(base_hl, dim_opacity, bg)
    end
  end

  if not highlights or #highlights == 0 then
    -- No syntax highlights — still need to split on emphasis boundaries
    return M._split_by_emphasis(text, base_hl, emph_hl, emph_ranges, dim_opacity)
  end

  -- Build character-level fg_hl map, then split into chunks by (fg_hl, bg_hl) boundaries
  local chunks = {}
  local pos = 0

  -- Merge syntax highlights with emphasis ranges by walking character by character
  -- through syntax segments and splitting at emphasis boundaries
  for _, sh in ipairs(highlights) do
    -- Gap before this syntax highlight
    if sh.col_start > pos then
      local sub_chunks =
        M._split_by_emphasis(text:sub(pos + 1, sh.col_start), base_hl, emph_hl, emph_ranges, dim_opacity, pos)
      vim.list_extend(chunks, sub_chunks)
    end

    -- Syntax highlighted segment — split at emphasis boundaries
    local seg_start = math.max(sh.col_start, pos)
    local seg_end = sh.col_end
    if seg_start < seg_end then
      local sub_chunks = M._split_by_emphasis(
        text:sub(seg_start + 1, seg_end),
        base_hl,
        emph_hl,
        emph_ranges,
        dim_opacity,
        seg_start,
        sh.hl_group
      )
      vim.list_extend(chunks, sub_chunks)
    end

    pos = math.max(pos, sh.col_end)
  end

  -- Trailing text
  if pos < #text then
    local sub_chunks = M._split_by_emphasis(text:sub(pos + 1), base_hl, emph_hl, emph_ranges, dim_opacity, pos)
    vim.list_extend(chunks, sub_chunks)
  end

  if #chunks == 0 then
    chunks[#chunks + 1] = { text, M.make_hl(base_hl, dim_opacity, base_hl) }
  end

  return chunks
end

--- Split a text segment into chunks based on emphasis range boundaries.
---@param text string segment text
---@param base_hl string base diff bg highlight
---@param emph_hl string emphasis diff bg highlight
---@param emph_ranges number[][] emphasis ranges in original line coordinates
---@param dim_opacity number
---@param offset? number character offset of this segment in the full line (default 0)
---@param fg_hl? string syntax fg highlight group (nil = use base)
---@return {[1]: string, [2]: string}[]
function M._split_by_emphasis(text, base_hl, emph_hl, emph_ranges, dim_opacity, offset, fg_hl)
  offset = offset or 0
  if #text == 0 then
    return {}
  end

  local chunks = {}
  local pos = 0

  while pos < #text do
    local col = offset + pos
    local is_emph = in_emphasis(col, emph_ranges)
    local bg = is_emph and emph_hl or base_hl

    -- Find how far this emphasis state extends
    local run_end = pos + 1
    while run_end < #text do
      local next_emph = in_emphasis(offset + run_end, emph_ranges)
      if next_emph ~= is_emph then
        break
      end
      run_end = run_end + 1
    end

    local chunk_text = text:sub(pos + 1, run_end)
    local hl = M.make_hl(fg_hl or base_hl, dim_opacity, bg)
    chunks[#chunks + 1] = { chunk_text, hl }
    pos = run_end
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
