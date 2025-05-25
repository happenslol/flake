local g, opt = vim.g, vim.opt

g.mapleader = " "
g.maplocalleader = " "

opt.clipboard = "unnamedplus" -- Connection to the system clipboard
opt.cmdheight = 0 -- Hide command line unless needed
opt.completeopt = { "menuone", "noselect" } -- Options for insert mode completion
opt.copyindent = true -- Copy the previous indentation on autoindenting
opt.cursorline = false -- Don't highlight the text line of the cursor
opt.expandtab = true -- Enable the use of space in tab
opt.fileencoding = "utf-8" -- File content encoding for the buffer
opt.fillchars = { eob = " " } -- Disable `~` on nonexistent lines
opt.history = 100 -- Number of commands to remember in a history table
opt.ignorecase = true -- Case insensitive searching
opt.infercase = true -- Infer cases in keyword completion
opt.laststatus = 3 -- globalstatus
opt.mouse = "a" -- Enable mouse support
opt.number = true -- Show numberline
opt.preserveindent = true -- Preserve indent structure as much as possible
opt.pumheight = 10 -- Max height of the pop up menu
opt.scrolloff = 8 -- Number of lines to keep above and below the cursor
opt.shiftwidth = 2 -- Number of space inserted for indentation
opt.showmode = false -- Disable showing modes in command line
opt.sidescrolloff = 8 -- Number of columns to keep at the sides of the cursor
opt.signcolumn = "yes" -- Always show the sign column
opt.smartcase = true -- Case sensitivie searching
opt.smartindent = true -- Smarter autoindentation
opt.splitbelow = true -- Splitting a new window below the current one
opt.splitright = true -- Splitting a new window at the right of the current one
opt.tabstop = 2 -- Number of space in a tab
opt.termguicolors = true -- Enable 24-bit RGB color in the TUI
opt.undofile = true -- Enable persistent undo
opt.updatetime = 200 -- Length of time to wait before triggering the plugin
opt.virtualedit = "block" -- Allow going past end of line in visual block mode
opt.wrap = true -- Disable wrapping of lines longer than the width of window
opt.writebackup = false -- Disable making a backup before overwriting a file
opt.swapfile = false -- Disable swapfiles
opt.startofline = false -- Don't move the cursor when moving a line
opt.title = true -- Set the title for tmux pane titles
opt.shortmess = "aoctIF" -- Show no startup message
opt.breakindent = true -- Wrap indent to match line start
opt.linebreak = true -- Wrap lines at 'breakat'
opt.timeoutlen = 500 -- Time to wait for a mapped sequence to complete
opt.smartindent = false -- Disable smartindent (breaks indenting lines starting with #)
opt.foldlevel = 99
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.inccommand = "nosplit" -- preview incremental substitute
opt.jumpoptions = "view"
opt.sessionoptions = { "buffers", "winsize", "folds" }
opt.winminwidth = 5 -- Minimum window width
opt.formatexpr = "v:lua.require'conform'.formatexpr()"
opt.formatoptions = "jcroqlnt" -- tcqj

opt.titlestring = "nvim | %{substitute(getcwd(), $HOME, '~', '')}"

opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

-- Remove help entry from mouse menu
vim.cmd.aunmenu("PopUp.How-to\\ disable\\ mouse")
vim.cmd.aunmenu("PopUp.-1-")

-- neovim 0.10
opt.smoothscroll = true
opt.foldexpr = "v:lua.require'util'.foldexpr()"
opt.foldmethod = "expr"
opt.foldtext = ""

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0
