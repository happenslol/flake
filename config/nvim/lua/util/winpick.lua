-- Copyright 2021 Gabriel Sanches
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
-- associated documentation files (the "Software"), to deal in the Software without restriction,
-- including without limitation the rights to use, copy, modify, merge, publish, distribute,
-- sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all copies or substantial
-- portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
-- NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
-- OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
-- CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

local api = vim.api

local ESC_CODE = 27

local M = {}

local ignored_fts = {
  ["noice"] = true,
  ["neo-tree"] = true,
  ["neo-tree-popup"] = true,
  ["notify"] = true,
  ["help"] = true,
}

local ignored_buftypes = {
  ["terminal"] = true,
  ["quickfix"] = true,
  ["nofile"] = true,
  ["prompt"] = true,
  ["popup"] = true,
}

local alphabet = {}
for char in ("FJDKSLA;CMRUEIWOQP"):gmatch(".") do
  table.insert(alphabet, char)
end

--- Shows visual cues for each window.
--- @param targets table: Map of labels and their respective window objects.
--- @return table: List of visual cues that were opened.
local function show_cues(targets)
  -- Reset view.
  local cues = {}
  for label, win in pairs(targets) do
    local bufnr = api.nvim_create_buf(false, true)

    local padding = string.rep(" ", 4)
    local fill = string.rep(" ", label:len())

    local lines = {
      padding .. fill .. padding,
      padding .. label .. padding,
      padding .. fill .. padding,
    }

    api.nvim_buf_set_lines(bufnr, 0, 0, false, lines)

    local width = label:len() + padding:len() * 2
    local height = 3

    local center_x = api.nvim_win_get_width(win.id) / 2
    local center_y = api.nvim_win_get_height(win.id) / 2

    local cue_bufnr = api.nvim_open_win(bufnr, false, {
      relative = "win",
      win = win.id,
      width = width,
      height = height,
      col = math.floor(center_x - width / 2),
      row = math.floor(center_y - height / 2),
      focusable = false,
      style = "minimal",
      border = "rounded",
    })

    pcall(api.nvim_set_option_value, "buftype", "nofile", {
      scope = "local",
      buf = cue_bufnr,
    })

    table.insert(cues, cue_bufnr)
  end

  return cues
end

--- Closes all windows for visual cues.
local function hide_cues(cues)
  for _, win in pairs(cues) do
    -- We use pcall here because we dont' want to throw an error just
    -- because we couldn't close a window that was probably already closed!
    pcall(api.nvim_win_close, win, true)
  end
end

--- Prompts for a window to be selected. A callback is used for handling the action. The default
--- action is to focus the selected window. The argument passed to the callback is a window ID if a
--- window is selected or nil if it the selection is aborted.
--- @return number | nil, number | nil: Selected window table containing ID and its corresponding buffer ID.
function M.select()
  local wins = api.nvim_tabpage_list_wins(0)
  wins = vim.tbl_map(function(winid)
    return {
      id = winid,
      bufnr = api.nvim_win_get_buf(winid),
    }
  end, wins)

  -- Filter out some buffers according to configuration.
  local eligible_wins = vim.tbl_filter(function(win)
    local ft = api.nvim_get_option_value("filetype", { buf = win.bufnr })
    if ignored_fts[ft] then
      return false
    end

    local buftype = api.nvim_get_option_value("buftype", { buf = win.bufnr })
    if ignored_buftypes[buftype] then
      return false
    end

    return true
  end, wins)

  if #eligible_wins == 0 then
    return nil, nil
  end

  if #eligible_wins == 1 then
    local win = eligible_wins[1]
    return win.id, win.bufnr
  end

  local targets = {}
  local chars = alphabet
  local total_chars = #chars

  if #eligible_wins > total_chars then
    vim.notify(
      "The number of eligible windows is greater than the number of label characters, some windows will never be picked",
      vim.log.levels.WARN
    )
  end

  for idx, win in ipairs(eligible_wins) do
    local next_char = chars[idx % (total_chars + 1)]
    targets[next_char] = win
  end

  local cues = show_cues(targets)

  vim.cmd("mode") -- clear cmdline once
  print("")

  local ok, choice = pcall(vim.fn.getchar) -- Ctrl-C returns an error

  vim.cmd("mode") -- clear cmdline again to remove pick-up message
  hide_cues(cues)

  local is_ctrl_c = not ok
  local is_esc = choice == ESC_CODE

  if is_ctrl_c or is_esc then
    return nil, nil
  end

  local choice_char = string.char(choice):upper()

  local win = targets[choice_char]
  if not win then
    return nil, nil
  end

  return win.id, win.bufnr
end

return M
