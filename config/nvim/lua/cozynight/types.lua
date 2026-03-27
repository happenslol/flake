---@class cozynight.Highlight: vim.api.keyset.highlight
---@field style? vim.api.keyset.highlight

---@alias cozynight.Highlights table<string,cozynight.Highlight|string>

---@alias cozynight.HighlightsFn fun(colors: ColorScheme, opts:cozynight.Config):cozynight.Highlights

---@class cozynight.Cache
---@field groups cozynight.Highlights
---@field inputs table
