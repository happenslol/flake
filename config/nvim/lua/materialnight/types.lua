---@class materialnight.Highlight: vim.api.keyset.highlight
---@field style? vim.api.keyset.highlight

---@alias materialnight.Highlights table<string,materialnight.Highlight|string>

---@alias materialnight.HighlightsFn fun(colors: ColorScheme, opts:materialnight.Config):materialnight.Highlights

---@class materialnight.Cache
---@field groups materialnight.Highlights
---@field inputs table
