local map = vim.keymap.set

map({ "n", "v" }, ";", ":")
map({ "n", "v" }, "'", '"')

-- Mouse buttons back/forward
map({ "n", "v" }, "<X1Mouse>", "<c-o>", { silent = true })
map({ "n", "v" }, "<X2Mouse>", "<c-i>", { silent = true })

-- Better up/down
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Resize window using <ctrl> arrow keys
map("n", "<c-up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<c-down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<c-left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<c-right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move Lines
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move down", silent = true })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move up", silent = true })

-- quicksave
map("n", "<leader>w", ":w<cr>", { silent = true, desc = "Quicksave" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Better indenting
map("v", "<", "<gv", { desc = "Indent Left" })
map("v", ">", ">gv", { desc = "Indent Right" })

-- lazy
map("n", "<leader>ll", "<cmd>:Lazy<cr>", { desc = "Lazy" })

-- Scroll active buffer using scrollwheel
map("n", "<ScrollWheelUp>", "3<c-y>", { silent = true })
map("n", "<ScrollWheelDown>", "3<c-e>", { silent = true })

-- Select next/previous line using scrollwheel in visual mode
map("v", "<ScrollWheelUp>", "k", { silent = true })
map("v", "<ScrollWheelDown>", "j", { silent = true })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Clear highlights on <esc> in normal mode
map("n", "<esc>", function()
  vim.cmd("nohlsearch")
  if vim.snippet.active() then
    vim.snippet.stop()
  end

  return "<esc>"
end, { silent = true, expr = true })

-- Restart LSP and show info
map("n", "<leader>li", ":lsp info<cr>", { silent = true, desc = "Show LSP Info" })
map("n", "<leader>lr", ":lsp restart<cr>", { silent = true, desc = "Restart LSPs" })

-- Clear current session and buffers
map("n", "<leader>lc", function()
  vim.cmd("vnew")
  vim.cmd("only")

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      local hidden = vim.fn.bufwinid(buf) == -1
      if hidden or name == "" then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
      end
    end
  end
end, { silent = true, desc = "Clear Session" })

-- Copy current buffer name to clipboard

map("n", "<leader>lp", function()
  local full_filename = vim.fn.expand("%:t")
  if not full_filename or full_filename == "" then
    vim.notify("No filename available")
    return
  end

  vim.fn.setreg("+", full_filename)
  vim.notify("Copied `" .. full_filename .. "` to clipboard")
end, { silent = true, desc = "Copy Current Buffer Name" })

-- Reload cozynight theme (clear module cache, reapply highlights, refresh lualine)
local function reload_theme()
  for name, _ in pairs(package.loaded) do
    if name:match("^cozynight") or name:match("^lualine%.themes%.cozynight") then
      package.loaded[name] = nil
    end
  end
  require("cozynight").load()
  if package.loaded["lualine"] then
    package.loaded["lualine.themes.cozynight"] = nil
    require("lualine").setup({ options = { theme = "cozynight" } })
  end
end

map("n", "<leader>tr", function()
  reload_theme()
  vim.notify("Theme reloaded")
end, { silent = true, desc = "Reload Theme" })

-- Toggle live theme reload (watches cozynight source files via libuv)
local _cozynight_watchers = nil

map("n", "<leader>tw", function()
  if _cozynight_watchers then
    -- Stop watching
    for _, w in ipairs(_cozynight_watchers) do
      w:stop()
    end
    _cozynight_watchers = nil
    vim.notify("Theme live reload stopped")
    return
  end

  local theme_dir = vim.fn.stdpath("config") .. "/lua/cozynight"
  local watchers = {}
  local watched_files = {}

  local reload = vim.schedule_wrap(reload_theme)

  local function watch_file(path)
    if watched_files[path] then
      return
    end
    local w = vim.uv.new_fs_event()
    w:start(path, {}, function(err)
      if not err then
        reload()
      end
    end)
    watched_files[path] = w
    table.insert(watchers, w)
  end

  -- Watch directories for new files, and all existing .lua files
  local function watch_dir(dir)
    local handle = vim.uv.fs_scandir(dir)
    if not handle then
      return
    end

    -- Watch the directory itself to detect new files
    local dw = vim.uv.new_fs_event()
    dw:start(dir, {}, function(err, filename)
      if err then
        return
      end
      vim.schedule(function()
        if filename and filename:match("%.lua$") then
          local path = dir .. "/" .. filename
          if vim.uv.fs_stat(path) and not watched_files[path] then
            watch_file(path)
            reload()
          end
        end
      end)
    end)
    table.insert(watchers, dw)

    while true do
      local name, typ = vim.uv.fs_scandir_next(handle)
      if not name then
        break
      end
      local path = dir .. "/" .. name
      if typ == "directory" then
        watch_dir(path)
      elseif name:match("%.lua$") then
        watch_file(path)
      end
    end
  end

  watch_dir(theme_dir)
  -- Also watch lualine theme
  local lualine_theme = vim.fn.stdpath("config") .. "/lua/lualine/themes/cozynight.lua"
  if vim.uv.fs_stat(lualine_theme) then
    watch_file(lualine_theme)
  end

  _cozynight_watchers = watchers
  vim.notify("Theme live reload active (" .. #watchers .. " watchers)")
end, { silent = true, desc = "Toggle Theme Live Reload" })

map("n", "<leader>lP", function()
  local relative_path = vim.fn.expand("%:.")
  if not relative_path or relative_path == "" then
    vim.notify("No file path available")
    return
  end

  vim.fn.setreg("+", relative_path)
  vim.notify("Copied `" .. relative_path .. "` to clipboard")
end, { silent = true, desc = "Copy Current Buffer Relative Path" })
