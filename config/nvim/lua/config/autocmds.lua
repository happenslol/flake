local function augroup(name)
  return vim.api.nvim_create_augroup("custom_" .. name, { clear = true })
end

-- Clear registers on startup
vim.api.nvim_create_autocmd("VimEnter", {
  group = augroup("clear_registers"),
  callback = function()
    for i = 97, 122 do
      local char = string.char(i)
      vim.fn.setreg(char, "")
    end
  end,
})

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  command = "checktime",
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].lazyvim_last_loc then
      return
    end
    vim.b[buf].lazyvim_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Cancel snippet session when leaving insert
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = function()
    local loaded, luasnip = pcall(require, "luasnip")
    if not loaded then
      return
    end

    if
      ((vim.v.event.old_mode == "s" and vim.v.event.new_mode == "n") or vim.v.event.old_mode == "i")
      and luasnip.session.current_nodes[vim.api.nvim_get_current_buf()]
      and not luasnip.session.jump_active
    then
      luasnip.unlink_current()
    end
  end,
})

-- Always put help windows on the right
vim.api.nvim_create_autocmd("BufEnter", {
  group = augroup("help"),
  pattern = "*.txt",
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "help" then
      return
    end

    vim.cmd.wincmd("L")
    vim.api.nvim_win_set_width(0, 90)
  end,
})

-- Close several window types with q
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("quit"),
  pattern = "help,lspinfo,qf,startuptime,fugitive",
  callback = function(event)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Add resize keybindings to neo-tree
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("neo-tree"),
  pattern = "neo-tree",
  callback = function(event)
    vim.keymap.set("n", "<c-l>", "<cmd>vertical resize +15<cr>", { buffer = event.buf, silent = true })
    vim.keymap.set("n", "<c-h>", "<cmd>vertical resize -15<cr>", { buffer = event.buf, silent = true })
  end,
})

vim.filetype.add({
  pattern = {
    [".*"] = {
      function(path, buf)
        return vim.bo[buf]
            and vim.bo[buf].filetype ~= "bigfile"
            and path
            and vim.fn.getfsize(path) > vim.g.bigfile_size
            and "bigfile"
          or nil
      end,
    },
  },
})

vim.api.nvim_create_autocmd({ "FileType" }, {
  group = augroup("bigfile"),
  pattern = "bigfile",
  callback = function(ev)
    vim.b.minianimate_disable = true
    vim.schedule(function()
      vim.bo[ev.buf].syntax = vim.filetype.match({ buf = ev.buf }) or ""
    end)
  end,
})
