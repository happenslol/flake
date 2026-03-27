local config = require("materialnight.config")

local M = {}
---@type {light?: string, dark?: string}
M.styles = {}

---@param opts? materialnight.Config
function M.load(opts)
  opts = require("materialnight.config").extend(opts)

  M.styles["dark"] = opts.style
  return require("materialnight.theme").setup(opts)
end

M.setup = config.setup

return M
