return {
	{ "nmac427/guess-indent.nvim", config = true },
	{ "kylechui/nvim-surround",    config = true, event = "VeryLazy" },

	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {
			check_ts = true,
			ts_config = { java = false },
			-- TODO: Test this
			fast_wrap = {
				map = "<M-e>",
				chars = { "{", "[", "(", '"', "'" },
				pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
				offset = 0,
				end_key = "$",
				keys = "qwertyuiopzxcvbnmasdfghjkl",
				check_comma = true,
				highlight = "PmenuSel",
				highlight_grey = "LineNr",
			},
		},
		config = function(_, opts)
			local npairs = require("nvim-autopairs")
			npairs.setup(opts)

			local cmp_status_ok, cmp = pcall(require, "cmp")
			if cmp_status_ok then
				cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done({ tex = false }))
			end
		end,
	},

	{
		"numToStr/Comment.nvim",
		dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
		keys = { { "gc", mode = { "n", "v" } }, { "gb", mode = { "n", "v" } } },
		opts = function()
			local commentstring = require("ts_context_commentstring.integrations.comment_nvim")
			return { pre_hook = commentstring.create_pre_hook() }
		end,
	},

	{
		"Wansmer/treesj",
		keys = { { "<leader>w", "<cmd>TSJToggle<cr>", desc = "Toggle Split/Join Line" } },
		opts = { use_default_keymaps = false },
		dependencies = { "nvim-treesitter/nvim-treesitter" },
		config = true,
	},
}
