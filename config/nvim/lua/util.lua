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

function M.filter_code_actions(results)
  -- We get a list of results from each lsp here,
  -- so we need to flatten them into one list before sorting
  local all_results = {}
  for _, result in ipairs(results) do
    if result.result then
      for _, r in ipairs(result.result) do
        table.insert(all_results, r)
      end
    end
  end

  table.sort(all_results, function(a, b)
    return get_code_action_priority(a.title) > get_code_action_priority(b.title)
  end)

  return { { result = all_results } }
end

return M
