--- Extmark-based highlight utilities for diff buffers.
local M = {}

--- Clear all diffv highlights from a buffer.
---@param buf number buffer handle
function M.clear(buf)
  local ns = require("diffv").ns()
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

return M
