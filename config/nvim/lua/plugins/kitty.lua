return {
  {
    "mikesmithgh/kitty-scrollback.nvim",
    enabled = true,
    lazy = true,
    cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
    event = { "User KittyScrollbackLaunch" },
    config = function()
      require("kitty-scrollback").setup({
        callbacks = {
          after_ready = vim.defer_fn(function()
            vim.keymap.set("n", "q", "<cmd>qa!<cr>", { buffer = true, silent = true })
            vim.opt.signcolumn = "no"
          end, 0)
        }
      })
    end,
  },
}
