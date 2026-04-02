--- Built-in actions for diffv keymaps.
--- Each action is a function that operates on the active view state.
--- These can be referenced by name (string) in keymap config,
--- or used directly as function values.
local M = {}

function M.close()
  local state = require("diffv.state").active
  if state then
    state:destroy()
  end
end

function M.toggle_layout()
  require("diffv.ui").toggle_layout()
end

function M.increase_context()
  require("diffv.ui").adjust_context(5)
end

function M.decrease_context()
  require("diffv.ui").adjust_context(-5)
end

function M.toggle_context()
  require("diffv.ui").toggle_context()
end

function M.next_file()
  local state = require("diffv.state").active
  if state then
    local next = state.current_file + 1
    if next <= #state.files then
      state:select_file(next)
    end
  end
end

function M.prev_file()
  local state = require("diffv.state").active
  if state then
    local prev = state.current_file - 1
    if prev >= 1 then
      state:select_file(prev)
    end
  end
end

function M.next_hunk()
  -- TODO
end

function M.prev_hunk()
  -- TODO
end

--- Filelist-only: select the file under cursor.
--- This is a no-op outside the filelist; the filelist binds its own
--- closure that captures the window/state context.
M.select = nil -- handled specially by filelist

return M
