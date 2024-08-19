-- This needs to live at the root so that neo-tree finds this when it
-- requires 'window-picker'.
local M = {}

function M.pick_window()
  local win, _ = require("util.winpick").select()
  return win
end

return M
