local telescope = require "telescope"
local telescope_actions = require "telescope.actions"

local lsp_goto_config = {
	layout_strategy = "horizontal",
	sorting_strategy = "ascending",
	layout_config = {
		prompt_position = "top",
		width = 0.7,
		height = 0.6,
	},
}

telescope.setup {
  defaults = {
    mappings = {
      i = {
        ["<esc>"] = telescope_actions.close,
        ["<c-j>"] = telescope_actions.move_selection_next,
        ["<c-k>"] = telescope_actions.move_selection_previous,
      }
    },
  },

  pickers = {
    find_files = {
	    previewer = false,
			sorting_strategy = "ascending",
	    layout_config = {
		    prompt_position = "top",
		    width = 0.4,
		    height = 0.6,
	    },
    },
    live_grep = {
	    layout_strategy = "horizontal",
	    sorting_strategy = "ascending",
	    layout_config = {
		    prompt_position = "top",
		    width = 0.9,
		    height = 0.8,
	    },
    },

    lsp_definitions = lsp_goto_config,
    lsp_implementations = lsp_goto_config,
    lsp_references = lsp_goto_config,
    lsp_document_symbols = lsp_goto_config,
    lsp_diagnostics = lsp_goto_config,
    lsp_lsp_type_definitions = lsp_goto_config,
  },

  extensions = {
    ["ui-select"] = {
      layout_strategy = "cursor",
      results_title = false,
      preview_title = false,
      prompt_title = false,
      prompt_prefix = " ",
      previewer = false,
      sorting_strategy = "ascending",
      initial_mode = "normal",
      layout_config = {
        width = 60,
        height = 10,
      },
    }
  }
}

telescope.load_extension "fzy_native"
telescope.load_extension "ui-select"
