return {
  "olimorris/persisted.nvim",
  lazy = false,

  opts = function()
    local should_load = os.getenv("NVIM_SESSION_BLANK") == nil

    vim.api.nvim_create_autocmd("User", {
      pattern = "PersistedSavePre",
      callback = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            local name = vim.api.nvim_buf_get_name(buf)
            local hidden = vim.fn.bufwinid(buf) == -1
            if hidden or name == "" then
              vim.api.nvim_buf_delete(buf, { force = true })
            end
          end
        end
      end,
    })

    return {
      use_git_branch = true,
      autostart = should_load,
      autoload = should_load,
      ignored_dirs = { "/nix", "/tmp" },

      -- TODO: This isn't working
      allowed_dirs = { "~/" },
    }
  end,
}
