--- Line-level diff engine using vim.diff() (xdiff library).
local M = {}

--- Split a string into lines, preserving trailing newline behavior.
---@param text string
---@return string[]
local function split_lines(text)
  local lines = {}
  for line in text:gmatch("([^\n]*)\n?") do
    lines[#lines + 1] = line
  end
  -- Remove the trailing empty string from the final \n match
  if lines[#lines] == "" then
    lines[#lines] = nil
  end
  return lines
end

--- Parse the unified diff output from vim.diff() into hunks.
---@param diff_text string unified diff output
---@param old_lines string[]
---@param new_lines string[]
---@return diffv.Hunk[]
local function parse_hunks(diff_text, old_lines, new_lines)
  local hunks = {}
  local current ---@type diffv.Hunk?
  local old_lnum, new_lnum = 0, 0

  for line in diff_text:gmatch("[^\n]*") do
    if line:match("^@@") then
      local os, oc, ns, nc = line:match("^@@%s+%-(%d+),?(%d*)%s+%+(%d+),?(%d*)%s+@@")
      os = tonumber(os) or 0
      oc = tonumber(oc) or 1
      ns = tonumber(ns) or 0
      nc = tonumber(nc) or 1
      old_lnum = os
      new_lnum = ns
      current = {
        old_start = os,
        old_count = oc,
        new_start = ns,
        new_count = nc,
        lines = {},
      }
      hunks[#hunks + 1] = current
    elseif current then
      local prefix = line:sub(1, 1)
      local content = line:sub(2)
      if prefix == "-" then
        current.lines[#current.lines + 1] = {
          type = "delete",
          content = content,
          old_lnum = old_lnum,
        }
        old_lnum = old_lnum + 1
      elseif prefix == "+" then
        current.lines[#current.lines + 1] = {
          type = "add",
          content = content,
          new_lnum = new_lnum,
        }
        new_lnum = new_lnum + 1
      elseif prefix == " " then
        current.lines[#current.lines + 1] = {
          type = "context",
          content = content,
          old_lnum = old_lnum,
          new_lnum = new_lnum,
        }
        old_lnum = old_lnum + 1
        new_lnum = new_lnum + 1
      end
    end
  end

  return hunks
end

--- Compute a line-level diff between two strings.
---@param old_text string
---@param new_text string
---@param opts? { algorithm?: "myers" | "patience" | "histogram" }
---@return diffv.DiffResult
function M.diff(old_text, new_text, opts)
  opts = opts or {}
  local algorithm = opts.algorithm or "patience"

  local diff_text = vim.diff(old_text, new_text, {
    result_type = "unified",
    algorithm = algorithm,
    ctxlen = 999999, -- include all context lines
  })

  local old_lines = split_lines(old_text)
  local new_lines = split_lines(new_text)
  local hunks = parse_hunks(diff_text, old_lines, new_lines)

  return {
    hunks = hunks,
    old_lines = old_lines,
    new_lines = new_lines,
  }
end

--- Compute word-level diff within a pair of changed lines.
--- Returns column ranges (0-indexed, end-exclusive) of changed regions.
---@param old_line string
---@param new_line string
---@return { old_ranges: number[][], new_ranges: number[][] }
function M.word_diff(old_line, new_line)
  -- Split lines into characters for character-level diffing
  local old_chars = old_line .. "\n"
  local new_chars = new_line .. "\n"

  -- Use vim.diff with indices result type for efficiency
  local indices = vim.diff(old_chars, new_chars, {
    result_type = "indices",
    algorithm = "patience",
  })

  local old_ranges = {}
  local new_ranges = {}

  for _, hunk in ipairs(indices) do
    local old_start, old_count, new_start, new_count = hunk[1], hunk[2], hunk[3], hunk[4]
    if old_count > 0 then
      -- Convert from 1-indexed line (char) positions to 0-indexed byte columns
      old_ranges[#old_ranges + 1] = { old_start - 1, old_start - 1 + old_count }
    end
    if new_count > 0 then
      new_ranges[#new_ranges + 1] = { new_start - 1, new_start - 1 + new_count }
    end
  end

  return { old_ranges = old_ranges, new_ranges = new_ranges }
end

return M
