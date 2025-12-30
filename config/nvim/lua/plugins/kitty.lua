-- This is only included here to make sure lazy keeps this up to date - actual
-- configuration/usage is in kitty-scrollback-init.lua

---@type LazySpec
return {
  {
    "happenslol/kitty-scrollback.nvim",
    branch = "make-scrollback-cols-configurable",
    enabled = true,
    lazy = true,
  },
}
