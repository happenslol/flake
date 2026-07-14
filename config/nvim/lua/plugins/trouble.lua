-- Populate the quickfix list with git hunks (via gitsigns) and show them in a
-- dedicated Trouble mode. Toggles the window like the other Trouble mappings.
local function toggle_hunks(target)
  local trouble = require("trouble")
  if trouble.is_open("git_hunks") then
    trouble.close("git_hunks")
  else
    require("gitsigns").setqflist(target, { open = false }, function()
      vim.schedule(function()
        trouble.open({ mode = "git_hunks" })
      end)
    end)
  end
end

return {
  "folke/trouble.nvim",
  cmd = { "Trouble" },
  opts = {
    modes = {
      lsp = {
        win = { position = "right" },
      },
      -- Git hunks reused from the quickfix list populated by gitsigns.
      git_hunks = {
        mode = "qflist",
        desc = "Changed Hunks",
        focus = true,
        win = { size = 20 },
        format = "{git_hunk} {pos}",
      },
    },
    formatters = {
      -- gitsigns builds each entry as "<Kind> (<-removed +added>): <line>".
      -- Render it as an icon + a git-style coloured diffstat instead.
      git_hunk = function(ctx)
        local text = ctx.item.text or ""
        local kind, stat, line = text:match("^(%a+)%s*%((.-)%):%s*(.*)$")
        if not kind then
          return { { text = text } }
        end
        local icons = {
          Added = { icon = "", hl = "GitSignsAdd" },
          Removed = { icon = "", hl = "GitSignsDelete" },
          Changed = { icon = "", hl = "GitSignsChange" },
        }
        local info = icons[kind] or icons.Changed
        local parts = { { text = info.icon .. "  ", hl = info.hl } }
        for token in stat:gmatch("%S+") do
          local hl = token:sub(1, 1) == "+" and "GitSignsAdd" or "GitSignsDelete"
          parts[#parts + 1] = { text = token .. " ", hl = hl }
        end
        if line ~= "" then
          parts[#parts + 1] = { text = " " .. line }
        end
        return parts
      end,
    },
  },
  -- stylua: ignore
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols (Trouble)" },
    { "<leader>xS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/definitions/... (Trouble)" },
    { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
    { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    { "<leader>gq", function() toggle_hunks("all") end, desc = "Changed Hunks (Trouble)" },
    { "<leader>gQ", function() toggle_hunks(0) end, desc = "Buffer Hunks (Trouble)" },
    {
      "[q",
      function()
        if require("trouble").is_open() then
          ---@diagnostic disable-next-line: missing-fields, missing-parameter
          require("trouble").prev({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cprev)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end
      end,
      desc = "Previous Trouble/Quickfix Item",
    },
    {
      "]q",
      function()
        if require("trouble").is_open() then
          ---@diagnostic disable-next-line: missing-fields, missing-parameter
          require("trouble").next({ skip_groups = true, jump = true })
        else
          local ok, err = pcall(vim.cmd.cnext)
          if not ok then
            vim.notify(err, vim.log.levels.ERROR)
          end
        end
      end,
      desc = "Next Trouble/Quickfix Item",
    },
  },
}
