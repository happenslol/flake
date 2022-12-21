local packer_config = {
  display = {
    open_fn = function()
      return require "packer.util".float { border = "rounded" }
    end,
  },
}

require "packer".startup({ function()
  use "wbthomason/packer.nvim"

  -- Performance
  use "lewis6991/impatient.nvim"

  -- Theme
  use "kyazdani42/nvim-web-devicons"
  use { "catppuccin/nvim",
    as = "catppuccin",
    config = function() require "plugins.catppuccin" end,
  }

  -- UI Improvements
  use { "stevearc/dressing.nvim",
    config = function() require "plugins.dressing" end,
  }

  -- Scrollbar
  use { "petertriho/nvim-scrollbar",
    config = function()
      require "scrollbar".setup {
        excluded_filetypes = { "TelescopePrompt", "prompt", "neo-tree" },
        marks = { Cursor = { text = "" } },
      }
    end,
  }

  -- Notifications
  use { "rcarriga/nvim-notify",
    event = "UIEnter",
    config = function()
      require "notify".setup { stages = { "fade" } }
    end,
  }

  -- Status bar
  use { "nvim-lualine/lualine.nvim",
    config = function() require "plugins.lualine" end,
  }

  -- File tree
  -- TODO: See neo-tree.lua
  -- use { "nvim-neo-tree/neo-tree.nvim",
  --   branch = "v2.x",
  --   config = function() require "plugins.neo-tree" end,
  --   requires = {
  --     "nvim-lua/plenary.nvim",
  --     "kyazdani42/nvim-web-devicons",
  --     "MunifTanjim/nui.nvim",
  --     { "s1n7ax/nvim-window-picker",
  --       tag = "v1.*",
  --       config = function() require "plugins.window-picker" end,
  --     }
  --   },
  -- }

  use { "kyazdani42/nvim-tree.lua",
    config = function() require "plugins.nvim-tree" end,
  }

  -- Fuzzy searching
  use { "nvim-telescope/telescope.nvim",
    requires = {
      "nvim-telescope/telescope-fzy-native.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
    },
    config = function() require "plugins.telescope" end,
  }

  -- LSP Diagnostic viewer
  use { "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require "trouble".setup { use_diagnostic_signs = true }
    end
  }

  -- Treesitter
  use { "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
    event = "BufEnter",
    cmd = {
      "TSInstall", "TSInstallInfo", "TSInstallSync",
      "TSUninstall", "TSUpdate", "TSUpdateSync",
      "TSDisableAll", "TSEnableAll",
    },
    config = function() require "plugins.treesitter" end,
  }

  use { "windwp/nvim-ts-autotag",
    after = "nvim-treesitter",
  }

  use { "JoosepAlviste/nvim-ts-context-commentstring",
    after = "nvim-treesitter",
  }

  -- Automatic closing parens and tags
  use { "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require "nvim-autopairs".setup { check_ts = true }
    end,
  }

  -- Indent style detection
  use { "Darazaki/indent-o-matic",
    config = function()
      require "indent-o-matic".setup {
        max_lines = 2048,
        standard_widths = { 2, 4 },
        skip_multiline = false,
      }
    end,
  }

  -- Code commenting
  use { "numToStr/Comment.nvim",
    config = function() require "Comment".setup() end,
  }

  -- Arg wrapping
  use "FooSoft/vim-argwrap"

  -- Modify surrounds
  use { "kylechui/nvim-surround",
    config = function() require("nvim-surround").setup() end,
  }

  -- Colorizer
  use { "NvChad/nvim-colorizer.lua",
    config = function() require "colorizer".setup {} end,
  }

  -- Extra json schemas
  use "b0o/SchemaStore.nvim"

  -- Extra text objects
  use "wellle/targets.vim"

  -- Improve quickfix window
  use { "kevinhwang91/nvim-bqf",
    ft = "qf",
    config = function()
      require "bqf".setup { func_map = require "keymaps".bqf }
    end,
  }

  -- Snippet source
  use { "rafamadriz/friendly-snippets", opt = true }

  -- Snippet engine
  use { "L3MON4D3/LuaSnip", wants = "friendly-snippets" }

  use { "hrsh7th/nvim-cmp" }

  -- Buffer completion source
  use "hrsh7th/cmp-nvim-lsp"
  use "hrsh7th/cmp-buffer"
  use "hrsh7th/cmp-path"
  use "saadparwaiz1/cmp_luasnip"


  -- LSP configuration
  use "neovim/nvim-lspconfig"

  -- Formatting and linting
  use { "jose-elias-alvarez/null-ls.nvim",
    config = function() require "plugins.null-ls" end,
  }

  -- LSP icons
  use "onsails/lspkind.nvim"

end, config = packer_config })
