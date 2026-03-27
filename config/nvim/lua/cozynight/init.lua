local config = require("cozynight.config")

local M = {}
---@type {light?: string, dark?: string}
M.styles = {}

---@param opts? cozynight.Config
function M.load(opts)
  opts = require("cozynight.config").extend(opts)

  M.styles["dark"] = opts.style
  return require("cozynight.theme").setup(opts)
end

M.setup = config.setup

return M
