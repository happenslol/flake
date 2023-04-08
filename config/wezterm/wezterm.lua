local w = require("wezterm")
local keymaps = require("keymaps")

local config = {}

config.colors = require("colors")

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.window_decorations = "NONE"

config.bold_brightens_ansi_colors = false
config.font = w.font("IosevkaTerm Nerd Font")

local function iosevka(weight, style)
  return w.font("IosevkaTerm Nerd Font", { weight = weight, style = style })
end

config.font_rules = {
  {
    intensity = "Normal",
    italic = false,
    font = iosevka("Medium", "Normal"),
  },
  {
    intensity = "Normal",
    italic = true,
    font = iosevka("Medium", "Italic"),
  },
  {
    intensity = "Bold",
    italic = false,
    font = iosevka("ExtraBold", "Normal"),
  },
  {
    intensity = "Bold",
    italic = true,
    font = iosevka("ExtraBold", "Italic"),
  },
  {
    intensity = "Half",
    italic = false,
    font = iosevka("Regular", "Normal"),
  },
  {
    intensity = "Half",
    italic = true,
    font = iosevka("Regular", "Italic"),
  },
}

config.disable_default_key_bindings = true

config.leader = keymaps.leader
config.keys = keymaps.keys
config.key_tables = keymaps.key_tables

config.window_close_confirmation = "NeverPrompt"

config.window_padding = {
  top = 0,
  right = 0,
  bottom = 0,
  left = 0,
}

config.tab_max_width = 40

local function append(t, v)
  t[#t + 1] = v
end

local function tab_title(tab)
  local title
  if tab.tab_title and #tab.tab_title > 0 then
    title = tab.tab_title
  else
    title = tab.active_pane.title
  end

  if #title > config.tab_max_width - 6 then
    title = title:sub(1, config.tab_max_width - 7) .. "…"
  end

  return title
end

w.on("format-tab-title", function(tab)
  local result = {}
  if tab.tab_index > 0 then
    append(result, { Background = { Color = "#212121" } })
    append(result, { Text = " " })
  end

  if tab.is_active then
    append(result, { Background = { AnsiColor = "Green" } })
  else
    append(result, { Foreground = { AnsiColor = "Silver" } })
    append(result, { Background = { AnsiColor = "Grey" } })
  end

  append(result, { Text = " " .. tostring(tab.tab_index + 1) .. " " })

  if tab.is_active then
    append(result, { Background = { AnsiColor = "Navy" } })
  else
    append(result, { Background = { AnsiColor = "Black" } })
  end

  append(result, { Text = " " .. tab_title(tab) .. " " })

  return result
end)

-- config.debug_key_events = true

return config
