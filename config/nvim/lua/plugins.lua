local packer_config = {
  display = {
    open_fn = function()
      return require "packer.util".float { border = "rounded" }
    end,
  },
}

require "packer".startup({function()
  use "wbthomason/packer.nvim"

  -- Performance
  use "lewis6991/impatient.nvim"

  -- Theme
  use "kaicataldo/material.vim"
  use "kyazdani42/nvim-web-devicons"

  -- UI Improvements
  use { "stevearc/dressing.nvim",
    config = function() require "plugins.dressing" end,
  }

  -- Notifications
  use { "rcarriga/nvim-notify",
    event = "UIEnter",
    config = function()
      require "notify".setup { stages = { "fade" }}
    end,
  }

  -- Util
  use { "s1n7ax/nvim-window-picker",
    tag = "v1.*",
    config = function() require "plugins.window-picker" end,
  }

  -- Status bar
  use { "feline-nvim/feline.nvim",
    config = function() require "plugins.feline" end,
    after = "material.vim",
  }

  -- File tree
  use { "nvim-neo-tree/neo-tree.nvim",
    branch = "v2.x",
    config = function() require "plugins.neo-tree" end,
    requires = {
      "nvim-lua/plenary.nvim",
      "kyazdani42/nvim-web-devicons",
      { "MunifTanjim/nui.nvim", module = "nui" },
    },
  }

  -- Fuzzy searching
  use { "nvim-telescope/telescope.nvim",
    requires = {
      "nvim-telescope/telescope-fzy-native.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
    },
    config = function() require "plugins.telescope" end,
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

  -- Extra json schemas
  use { "b0o/SchemaStore.nvim", module = "schemastore" }

end, config = packer_config})
