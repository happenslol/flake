local function augroup(name)
  return vim.api.nvim_create_augroup("custom_" .. name, { clear = true })
end

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
})

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

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  group = augroup("resize_splits"),
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
  end,
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

-- Close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "checkhealth",
    "dbout",
    "gitsigns-blame",
    "grug-far",
    "help",
    "lspinfo",
    "neotest-output",
    "neotest-output-panel",
    "neotest-summary",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
    "tsplayground",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, {
        buffer = event.buf,
        silent = true,
        desc = "Quit buffer",
      })
    end)
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
