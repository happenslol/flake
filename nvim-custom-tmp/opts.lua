local util = require "custom.util"

util.set_opt {
  breakindent = true,                                           -- Wrap indent to match  line start
  clipboard = "unnamedplus",                                    -- Connection to the system clipboard
  cmdheight = 0,                                                -- hide command line unless needed
  completeopt = { "menuone", "noselect" },                      -- Options for insert mode completion
  copyindent = true,                                            -- Copy the previous indentation on autoindenting
  cursorline = true,                                            -- Highlight the text line of the cursor
  expandtab = true,                                             -- Enable the use of space in tab
  fileencoding = "utf-8",                                       -- File content encoding for the buffer
  fillchars = { eob = " " },                                    -- Disable `~` on nonexistent lines
  foldenable = true,                                            -- enable fold for nvim-ufo
  foldlevel = 99,                                               -- set high foldlevel for nvim-ufo
  foldlevelstart = 99,                                          -- start with all code unfolded
  foldcolumn = vim.fn.has "nvim-0.9" == 1 and "1" or nil,       -- show foldcolumn in nvim 0.9
  history = 100,                                                -- Number of commands to remember in a history table
  ignorecase = true,                                            -- Case insensitive searching
  infercase = true,                                             -- Infer cases in keyword completion
  laststatus = 3,                                               -- globalstatus
  linebreak = true,                                             -- Wrap lines at 'breakat'
  mouse = "a",                                                  -- Enable mouse support
  number = true,                                                -- Show numberline
  preserveindent = true,                                        -- Preserve indent structure as much as possible
  pumheight = 10,                                               -- Height of the pop up menu
  relativenumber = true,                                        -- Show relative numberline
  scrolloff = 8,                                                -- Number of lines to keep above and below the cursor
  shiftwidth = 2,                                               -- Number of space inserted for indentation
  showmode = false,                                             -- Disable showing modes in command line
  showtabline = 2,                                              -- always display tabline
  sidescrolloff = 8,                                            -- Number of columns to keep at the sides of the cursor
  signcolumn = "yes",                                           -- Always show the sign column
  smartcase = true,                                             -- Case sensitivie searching
  smartindent = true,                                           -- Smarter autoindentation
  splitbelow = true,                                            -- Splitting a new window below the current one
  splitkeep = vim.fn.has "nvim-0.9" == 1 and "screen" or nil,   -- Maintain code view when splitting
  splitright = true,                                            -- Splitting a new window at the right of the current one
  tabstop = 2,                                                  -- Number of space in a tab
  termguicolors = true,                                         -- Enable 24-bit RGB color in the TUI
  timeoutlen = 500,                                             -- Shorten key timeout length a little bit for which-key
  undofile = true,                                              -- Enable persistent undo
  updatetime = 300,                                             -- Length of time to wait before triggering the plugin
  virtualedit = "block",                                        -- allow going past end of line in visual block mode
  wrap = false,                                                 -- Disable wrapping of lines longer than the width of window
  writebackup = false,                                          -- Disable making a backup before overwriting a file

  modeline = true,
  modelines = 5,

  numberwidth = 4,

  wildmenu = true,
  backspace = "indent,eol,start",
  fileencoding = "utf-8",

  binary = true,
  endofline = false,
  startofline = false,
  winminheight = 0,

  title = true,
  titlestring = "nvim | %{substitute(getcwd(), $HOME, '~', '')}",

  hlsearch = true,
  ignorecase = true,
  smartcase = true,
  incsearch = true,
  inccommand = "nosplit",
  errorbells = false,
  ruler = true,
  shortmess = "atIO",
  showcmd = true,
  scrolloff = 8,
  fillchars = { eob = " " },

  lazyredraw = true,
  termguicolors = true,

  expandtab = true,
  tabstop = 2,
  shiftwidth = 2,

  preserveindent = true,

  writebackup = false,
  swapfile = false,
  undofile = true,
  undodir = vim.fn.stdpath("data") .. "/undo",

  updatetime = 250,
}
