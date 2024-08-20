---@class util.formatting
---@field has_prettier_config fun(ctx: ConformCtx): boolean
---@field has_eslint_config fun(ctx: ConformCtx): boolean
---@alias ConformCtx {buf: number, filename: string, dirname: string}
local M = {}

---@param ctx ConformCtx
function M.has_prettier_config(ctx)
  vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
  return vim.v.shell_error == 0
end

---@param ctx ConformCtx
function M.has_eslint_config(ctx)
  local output = vim.fn.system({ "eslint_d", "--print-config", ctx.filename })
  return output ~= "undefined"
end

return M
