local M = {}

---@type diffv.Config
local defaults = {
  layout = "side_by_side",
  context = 5,
  git_cmd = "git",
  highlights = {
    add = "DiffAdd",
    delete = "DiffDelete",
    change = "DiffChange",
    change_text = "DiffText",
    context_separator = "Comment",
  },
  keymaps = {
    close = "q",
    toggle_layout = "<leader>dl",
    increase_context = "+",
    decrease_context = "-",
    next_hunk = "]h",
    prev_hunk = "[h",
  },
}

---@type diffv.Config
M.values = vim.deepcopy(defaults)

---@param opts? table
function M.setup(opts)
  M.values = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

return M
