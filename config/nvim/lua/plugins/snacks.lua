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
        grep = {
          hidden = true,
          ignored = false,
          exclude = { ".git" },
        },
        grep_word = {
          hidden = true,
          ignored = false,
          exclude = { ".git" },
        },
        files = {
          hidden = true,
          ignored = false,
          exclude = { ".git" },
          actions = {
            grep_in_files = function(picker)
              local paths = {}
              for i = 1, picker.list:count() do
                local item = picker.list:get(i)
                if item and item.file then
                  paths[#paths + 1] = (item.cwd or "") .. "/" .. item.file
                end
              end
              picker:close()
              Snacks.picker.grep({ dirs = paths })
            end,
          },
          win = {
            input = {
              keys = {
                ["<c-f>"] = { "grep_in_files", mode = { "i", "n" }, desc = "Grep in filtered files" },
              },
            },
          },
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
