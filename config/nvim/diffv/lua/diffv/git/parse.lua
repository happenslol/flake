--- Parse unified diff output from git into structured data.
local M = {}

--- Parse a hunk header (@@ -a,b +c,d @@) into numbers.
---@param header string the @@ line
---@return number old_start, number old_count, number new_start, number new_count
function M.parse_hunk_header(header)
  local os, oc, ns, nc = header:match("^@@%s+%-(%d+),?(%d*)%s+%+(%d+),?(%d*)%s+@@")
  if not os then
    return 0, 0, 0, 0
  end
  return tonumber(os) or 0, tonumber(oc) or 1, tonumber(ns) or 0, tonumber(nc) or 1
end

--- Map a single-letter git status to a human-readable status.
---@param s string single letter (M, A, D, R, etc.)
---@return "added" | "modified" | "deleted" | "renamed"
function M.status_letter(s)
  local map = {
    A = "added",
    M = "modified",
    D = "deleted",
    R = "renamed",
  }
  return map[s:sub(1, 1)] or "modified"
end

--- Parse unified diff output into a list of FileChange records.
---@param diff_output string raw unified diff text
---@return diffv.FileChange[]
function M.parse_diff(diff_output)
  local file_changes = {}
  local current ---@type diffv.FileChange?
  local current_hunk ---@type diffv.Hunk?
  local old_lnum, new_lnum = 0, 0

  for line in diff_output:gmatch("[^\n]*") do
    -- New file diff header
    if line:match("^diff %-%-git") then
      current = { path = "", status = "modified", hunks = {} }
      file_changes[#file_changes + 1] = current
      current_hunk = nil
    elseif current then
      -- Extract file path from +++ line
      if line:match("^%+%+%+ b/") then
        current.path = line:sub(7)
      elseif line:match("^%-%-%- a/") then
        current.old_path = line:sub(7)
      -- New file
      elseif line:match("^new file mode") then
        current.status = "added"
      elseif line:match("^deleted file mode") then
        current.status = "deleted"
      elseif line:match("^rename from") then
        current.status = "renamed"
      -- Hunk header
      elseif line:match("^@@") then
        local os, oc, ns, nc = M.parse_hunk_header(line)
        old_lnum = os
        new_lnum = ns
        current_hunk = {
          old_start = os,
          old_count = oc,
          new_start = ns,
          new_count = nc,
          lines = {},
        }
        current.hunks[#current.hunks + 1] = current_hunk
      elseif current_hunk then
        local prefix = line:sub(1, 1)
        local content = line:sub(2)
        if prefix == "+" then
          current_hunk.lines[#current_hunk.lines + 1] = {
            type = "add",
            content = content,
            new_lnum = new_lnum,
          }
          new_lnum = new_lnum + 1
        elseif prefix == "-" then
          current_hunk.lines[#current_hunk.lines + 1] = {
            type = "delete",
            content = content,
            old_lnum = old_lnum,
          }
          old_lnum = old_lnum + 1
        elseif prefix == " " then
          current_hunk.lines[#current_hunk.lines + 1] = {
            type = "context",
            content = content,
            old_lnum = old_lnum,
            new_lnum = new_lnum,
          }
          old_lnum = old_lnum + 1
          new_lnum = new_lnum + 1
        elseif line == "\\ No newline at end of file" then
          -- skip
        end
      end
    end
  end

  return file_changes
end

return M
