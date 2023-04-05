local w = require("wezterm")
local keymaps = require("keymaps")

local config = {}

config.colors = require("colors")

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.window_decorations = "NONE"

config.bold_brightens_ansi_colors = false
config.font = w.font_with_fallback({
  { family = "IosevkaTerm Nerd Font Mono Medium", weight = "Regular" },
  { family = "IosevkaTerm Nerd Font Mono Medium Italic", weight = "Regular", style = "Italic" },
  { family = "IosevkaTerm Nerd Font Mono Extrabold", weight = "Bold" },
  { family = "IosevkaTerm Nerd Font Mono Extrabold Italic", weight = "Bold", style = "Italic" },
})

config.enable_kitty_keyboard = true
config.disable_default_key_bindings = true

config.leader = keymaps.leader
config.keys = keymaps.keys
config.key_tables = keymaps.key_tables

-- config.debug_key_events = true

return config
