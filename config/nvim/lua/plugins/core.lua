return {
	-- Add https://github.com/kevinhwang91/nvim-ufo

	{
		"happenslol/materialnight.nvim",
		config = true,
		init = function()
			vim.cmd.colorscheme("materialnight")
		end,
	},

	{
		"nvim-neo-tree/neo-tree.nvim",
		dependencies = {
			{
				"s1n7ax/nvim-window-picker",
				lazy = true,
				opts = {
					other_win_hl_color = "#415580",
					fg_color = "#eeffff",
					include_current = false,
					autoselect_one = true,
					filter_rules = {
						bo = {
							filetype = { "neo-tree", "neo-tree-popup", "notify" },
							buftype = { "terminal", "quickfix" },
						},
					},
				},
			},
			"MunifTanjim/nui.nvim",
			"nvim-lua/plenary.nvim",
		},
		cmd = "Neotree",
		init = function()
			vim.g.neo_tree_remove_legacy_commands = true
		end,
		opts = {
			window = {
				width = 30,
				mappings = {
					["<cr>"] = "open_with_window_picker",
					["o"] = "open_with_window_picker",
				},
			},
			filesystem = {
				filtered_items = {
					visible = true,
				},
			},
		},
		keys = { { "<c-n>", "<cmd>Neotree toggle<cr>", desc = "Neotree" } },
	},

	{
		"nvim-telescope/telescope.nvim",
		version = false,
		dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope-fzf-native.nvim" },
		cmd = "Telescope",
		keys = {
			{ "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
			{ "<C-_>", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
		},
		opts = function()
			local telescope_actions = require("telescope.actions")

			local lsp_goto_config = {
				layout_strategy = "horizontal",
				sorting_strategy = "ascending",
				layout_config = {
					prompt_position = "top",
					width = 0.7,
					height = 0.6,
				},
			}

			return {
				defaults = {
					mappings = {
						i = {
							["<esc>"] = telescope_actions.close,
							["<c-j>"] = telescope_actions.move_selection_next,
							["<c-k>"] = telescope_actions.move_selection_previous,
						},
					},
				},
				extensions = {
					fzf = {},
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
			}
		end,
	},

	{
		"ggandor/flit.nvim",
		dependencies = { "ggandor/leap.nvim" },
		keys = function()
			local ret = {}
			for _, key in ipairs({ "f", "F", "t", "T" }) do
				ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
			end
			return ret
		end,
		opts = { labeled_modes = "nx" },
	},

	{
		"ggandor/leap.nvim",
		keys = {
			{ "s", mode = { "n", "x", "o" }, desc = "Leap forward to" },
			{ "S", mode = { "n", "x", "o" }, desc = "Leap backward to" },
			{ "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
		},
		config = function(_, opts)
			local leap = require("leap")
			for k, v in pairs(opts) do
				leap.opts[k] = v
			end
			leap.add_default_mappings(true)
			vim.keymap.del({ "x", "o" }, "x")
			vim.keymap.del({ "x", "o" }, "X")
		end,
	},

	{ "tpope/vim-repeat", event = "VeryLazy" },
}
