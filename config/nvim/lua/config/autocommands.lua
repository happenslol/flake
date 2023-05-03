local function augroup(name)
  return vim.api.nvim_create_augroup("custom_" .. name, { clear = true })
end

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  command = "checktime",
})

-- Go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Cancel snippet session when leaving insert
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = function()
    if
      ((vim.v.event.old_mode == "s" and vim.v.event.new_mode == "n") or vim.v.event.old_mode == "i")
      and require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
      and not require("luasnip").session.jump_active
    then
      require("luasnip").unlink_current()
    end
  end,
})

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

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("quit"),
  pattern = "help,lspinfo,qf,startuptime,fugitive",
  callback = function(event)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("neo-tree"),
  pattern = "neo-tree",
  callback = function(event)
    vim.keymap.set("n", "<c-l>", "<cmd>vertical resize +15<cr>", { buffer = event.buf, silent = true })
    vim.keymap.set("n", "<c-h>", "<cmd>vertical resize -15<cr>", { buffer = event.buf, silent = true })
  end,
})
