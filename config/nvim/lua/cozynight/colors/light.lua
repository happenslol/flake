---@param opts cozynight.Config
return function(opts)
  local Util = require("cozynight.util")

  ---@type Palette
  local colors = vim.deepcopy(Util.mod("cozynight.colors.dark"))

  ---@type Palette

  Util.invert(colors)
  ---@diagnostic disable-next-line: inject-field
  colors.bg_dark = Util.blend(colors.bg, 0.9, colors.fg)
  return colors
end
