return {
  {
    "happenslol/materialnight.nvim",
    config = true,
    init = function()
      vim.cmd.colorscheme("materialnight")

      local icons = { Error = " ", Warn = " ", Hint = " ", Info = " " }
      for name, icon in pairs(icons) do
        name = "DiagnosticSign" .. name
        vim.fn.sign_define(name, { text = icon, texthl = name })
      end
    end,
  },
}
