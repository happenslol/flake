return {
  "olimorris/persisted.nvim",
  lazy = false,

  dependencies = { "kazhala/close-buffers.nvim" },

  opts = function()
    local should_load = os.getenv("NVIM_SESSION_BLANK") == nil

    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistedSavePre",
      callback = function()
        local close = require("close_buffers")
        close.delete({ type = "hidden", force = true })
        close.delete({ type = "nameless", force = true })
      end,
    })

    return {
      use_git_branch = true,
      autostart = should_load,
      autoload = should_load,
      allowed_dirs = { "~" },
    }
  end,
}
