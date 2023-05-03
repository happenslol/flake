local M = {}

function M.on_attach(on_attach)
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
  return not vim.tbl_contains({
    "@typescript-eslint/no-unused-vars",
  }, diagnostic.code)
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

return M
