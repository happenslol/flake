-- Neo-tree windows have `winfixwidth` set and survive the `silent only` that a
-- session file starts with, so a tree that is open (and focused) while the
-- session is sourced ends up inheriting the width meant for the first restored
-- window, and the restored buffers get squeezed into what is left. Hitting <c-n>
-- right after startup wins that race easily, because persisted sources the
-- session from a `vim.schedule` callback.
--
-- So take the trees out of the way for the duration of the load and put them back
-- afterwards, which is also what makes a manual `:SessionLoad` behave.
local closed = {}

local function close_trees()
  closed = {}

  local wins = vim.api.nvim_tabpage_list_wins(0)
  local current = vim.api.nvim_get_current_win()
  local trees = {}

  for _, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "neo-tree" then
      table.insert(trees, { win = win, buf = buf })
    end
  end

  if #trees == 0 then
    return
  end

  -- `silent only` needs a non-tree window to land on
  if #trees == #wins then
    vim.cmd("noautocmd new")
  end

  for _, tree in ipairs(trees) do
    table.insert(closed, {
      source = vim.b[tree.buf].neo_tree_source,
      position = vim.b[tree.buf].neo_tree_position,
      focused = tree.win == current,
    })
    pcall(vim.api.nvim_win_close, tree.win, true)
  end
end

local function reopen_trees()
  local trees = closed
  closed = {}

  for _, tree in ipairs(trees) do
    if tree.source then
      -- "show" keeps the focus where the session put it, "focus" jumps to the tree
      require("neo-tree.command").execute({
        action = tree.focused and "focus" or "show",
        source = tree.source,
        position = tree.position,
      })
    end
  end
end

return {
  "olimorris/persisted.nvim",
  lazy = false,

  opts = function()
    local should_load = os.getenv("NVIM_SESSION_BLANK") == nil

    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistedLoadPre",
      callback = close_trees,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistedLoadPost",
      callback = reopen_trees,
    })

    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistedSavePre",
      callback = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            local name = vim.api.nvim_buf_get_name(buf)
            local hidden = vim.fn.bufwinid(buf) == -1
            if hidden or name == "" then
              vim.api.nvim_buf_delete(buf, { force = true })
            end
          end
        end
      end,
    })

    return {
      use_git_branch = true,
      autostart = should_load,
      autoload = should_load,
      ignored_dirs = { "/nix", "/tmp" },

      -- TODO: This isn't working
      allowed_dirs = { "~/" },
    }
  end,
}
