return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signcolumn = false,
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
        end

        -- stylua: ignore start
        map("n", "]h", gs.next_hunk, "Next Hunk")
        map("n", "[h", gs.prev_hunk, "Prev Hunk")
        map({ "n", "v" }, "<leader>gs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map({ "n", "v" }, "<leader>gr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>gt", gs.toggle_current_line_blame, "Toggle Current Line Blame")
        map("n", "<leader>gS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>gu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>gR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>gP", gs.preview_hunk, "Preview Hunk")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame Line")
        map("n", "<leader>gd", gs.diffthis, "Diff This")
        map("n", "<leader>gD", function() gs.diffthis("~") end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
        -- stylua: ignore end
      end,
    },
  },

  {
    "chrisgrieser/nvim-tinygit",
    event = "VeryLazy",
    -- stylua: ignore
    keys = {
      { "<leader>ga", function() require("tinygit").interactiveStaging() end, desc = "Stage" },
      { "<leader>gA", function() require("tinygit").amendNoEdit({ stageAllIfNothingChanged = true }) end, desc = "Amend all" },
      { "<leader>gg", function() require("tinygit").smartCommit() end, desc = "Commit" },
      { "<leader>gp", function() require("tinygit").push() end, desc = "Push" },
      { "<leader>gh", function() require("tinygit").fileHistory() end, desc = "File History" },
    },
  },

  { "akinsho/git-conflict.nvim", version = "*", config = true },
}
