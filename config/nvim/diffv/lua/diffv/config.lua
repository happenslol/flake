local M = {}

---@type diffv.Config
local defaults = {
  layout = "side_by_side",
  context = 10,
  git_cmd = "git",
  diff_engine = "line",
  highlights = {
    minus = "DiffvMinusBg",
    minus_emph = "DiffvMinusEmph",
    plus = "DiffvPlusBg",
    plus_emph = "DiffvPlusEmph",
    minus_nr = "DiffvMinusNr",
    plus_nr = "DiffvPlusNr",
    filler = "DiffvFiller",
    context_separator = "Comment",
  },
  status_icons = {
    M = "M",
    A = "A",
    D = "D",
    R = "R",
  },
  keymaps = {
    global = {
      ["q"] = "close",
      ["<C-j>"] = "next_file",
      ["<C-k>"] = "prev_file",
    },
    diff = {
      ["<leader>cv"] = "toggle_layout",
      ["+"] = "increase_context",
      ["-"] = "decrease_context",
      ["="] = "toggle_context",
      ["]h"] = "next_hunk",
      ["[h"] = "prev_hunk",
    },
    filelist = {
      ["<CR>"] = "select",
      ["<2-LeftMouse>"] = "select",
    },
  },
}

---@type diffv.Config
M.values = vim.deepcopy(defaults)

---@param opts? table
function M.setup(opts)
  M.values = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

--- Get the merged keymap for a view (global + view-specific).
--- View-specific bindings override global ones for the same key.
---@param view string "diff" or "filelist"
---@return table<string, string> key → action
function M.keymaps_for(view)
  local km = M.values.keymaps
  local merged = {}
  for key, action in pairs(km.global or {}) do
    merged[key] = action
  end
  for key, action in pairs(km[view] or {}) do
    merged[key] = action
  end
  return merged
end

return M
