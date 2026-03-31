return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,

  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    dashboard = { enabled = false },
    explorer = { enabled = false },
    indent = { enabled = false },
    input = { enabled = true },
    notifier = { enabled = false },
    quickfile = { enabled = true },
    scope = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = false },
    words = { enabled = false },
    picker = {
      enabled = true,
      sources = {
        files = {
          hidden = true,
          ignored = false,
          exclude = { ".git" },
        },
        select = {
          kinds = {
            codeaction = {
              layout = {
                layout = {
                  backdrop = false,
                  relative = "cursor",
                  row = 1,
                  col = 0,
                  width = 80,
                  height = 0,
                  min_height = 2,
                  box = "vertical",
                  border = "rounded",
                  title = "",
                  wo = { winhighlight = "FloatBorder:SnacksPickerCodeActionBorder" },
                  { win = "input", height = 1, border = "none" },
                  { win = "list", border = "none" },
                },
              },
            },
          },
        },
      },
      win = {
        input = {
          keys = {
            ["<Esc>"] = { "close", mode = { "n", "i" } },
            ["<c-j>"] = { "list_down", mode = { "i", "n" } },
            ["<c-k>"] = { "list_up", mode = { "i", "n" } },
          },
        },
        preview = {
          wo = { signcolumn = "no" },
        },
      },
      layout = {
        preset = "default",
      },
    },
  },

  keys = {
    {
      "<c-p>",
      function()
        Snacks.picker.files()
      end,
      desc = "Find Files",
    },
    {
      "<c-b>",
      function()
        Snacks.picker.resume()
      end,
      desc = "Resume",
    },
    {
      "<c-f>",
      function()
        Snacks.picker.grep()
      end,
      desc = "Live Grep",
    },
    {
      "<c-f>",
      function()
        Snacks.picker.grep_word()
      end,
      desc = "Grep Selection",
      mode = "v",
    },
    {
      "<leader>pg",
      function()
        Snacks.picker.git_status()
      end,
      desc = "Git Status",
    },
  },
}
