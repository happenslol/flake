local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = "plugins",
	install = {
		missing = true,
		colorscheme = { "materialnight", "slate" },
	},
	checker = { notify = false },
	change_detection = { notify = false },
	-- dev = {
	-- 	path = "~/code/nvim",
	-- 	patterns = { "happenslol" },
	-- 	fallback = false,
	-- },
	performance = {
		cache = { enabled = true },
		rtp = {
			reset = true,
			disabled_plugins = {
				"gzip",
				"matchit",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})
