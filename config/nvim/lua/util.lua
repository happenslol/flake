local M = {}

function M.on_lsp_attach(on_attach)
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local buffer = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      on_attach(client, buffer)
    end,
  })
end

function M.filter_diagnostics(diagnostics)
  return vim.tbl_filter(function(d)
    if d.source == "typescript" then
      -- Disable lints already covered by eslint
      return not vim.tbl_contains({
        6133, -- declared but never read
      }, d.code)
    end

    return true
  end, diagnostics)
end

function M.filter_eslintd_diagnostics(diagnostic)
  return true
  -- return not vim.tbl_contains({
  --   "@typescript-eslint/no-unused-vars",
  -- }, diagnostic.code)
end

local function get_code_action_priority(title)
  if title:find("^Apply suggested fix") then
    return 100
  end

  if title:find("^Update import from") then
    return 90
  end

  if title:find("^Add import from") then
    return 80
  end

  return 0
end

function M.sort_code_actions(results)
  for _, entry in ipairs(results) do
    table.sort(entry.result, function(a, b)
      return get_code_action_priority(a.title) > get_code_action_priority(b.title)
    end)
  end

  return results
end

function M.hook(tbl, key, fn)
  local prev = tbl[key]

  tbl[key] = function(...)
    fn(prev, ...)
  end
end

M.skip_foldexpr = {} ---@type table<number,boolean>
local skip_check = assert(vim.uv.new_check())

function M.foldexpr()
  local buf = vim.api.nvim_get_current_buf()

  -- still in the same tick and no parser
  if M.skip_foldexpr[buf] then
    return "0"
  end

  -- don't use treesitter folds for non-file buffers
  if vim.bo[buf].buftype ~= "" then
    return "0"
  end

  -- as long as we don't have a filetype, don't bother
  -- checking if treesitter is available (it won't)
  if vim.bo[buf].filetype == "" then
    return "0"
  end

  local ok = pcall(vim.treesitter.get_parser, buf)

  if ok then
    return vim.treesitter.foldexpr()
  end

  -- no parser available, so mark it as skip
  -- in the next tick, all skip marks will be reset
  M.skip_foldexpr[buf] = true
  skip_check:start(function()
    M.skip_foldexpr = {}
    skip_check:stop()
  end)
  return "0"
end

return M
