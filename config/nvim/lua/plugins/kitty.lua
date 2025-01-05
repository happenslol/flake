return {
  {
    "mikesmithgh/kitty-scrollback.nvim",
    enabled = true,
    lazy = true,
    cmd = { "KittyScrollbackGenerateKittens", "KittyScrollbackCheckHealth" },
    event = { "User KittyScrollbackLaunch" },
    config = function()
      require("kitty-scrollback").setup({
        {
          paste_window = {
            hide_footer = true,
            yank_register = "y",
          },
        },
        callbacks = {
          after_ready = vim.defer_fn(function()
            -- TODO: Keybindings don't show up with names in which-key
            vim.keymap.set("n", "q", "<cmd>qa!<cr>", { buffer = true, silent = true })
            vim.keymap.set("v", "y", function()
              print(vim.v.register)
              if vim.v.register == "+" then
                return "y<cmd>qa!<cr>"
              else
                return "y"
              end
            end, { buffer = true, expr = true, noremap = true })

            vim.opt.signcolumn = "no"
          end, 0),
        },
      })
    end,
  },
}
