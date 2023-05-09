local w = require("wezterm")
local keymaps = require("keymaps")

local config = {}

config.colors = require("colors")

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.window_decorations = "NONE"
config.show_new_tab_button_in_tab_bar = false

config.bold_brightens_ansi_colors = false
config.font = w.font("Iosevka Nerd Font")

local function iosevka(weight, style)
  return w.font("Iosevka Nerd Font", { weight = weight, style = style })
end

-- This feels sluggish, maybe revisit at some point
-- config.unix_domains = { { name = "default" } }
-- config.default_gui_startup_args = { "connect", "default" }

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

config.inactive_pane_hsb = {
  saturation = 0.7,
  brightness = 0.7,
}

config.disable_default_key_bindings = true

config.leader = keymaps.leader
config.keys = keymaps.keys
config.key_tables = keymaps.key_tables

config.window_close_confirmation = "NeverPrompt"

config.window_padding = {
  top = 8,
  right = 8,
  bottom = 4,
  left = 8,
}

config.tab_max_width = 60

local function append(t, v)
  t[#t + 1] = v
end

local function truncate_title(title)
  if #title <= config.tab_max_width - 8 then return title end
  return title:sub(1, config.tab_max_width - 9) .. "…"
end

local function format_dir(dir)
  local without_file_prefix = dir:gsub("^file://", "")
  local without_home = without_file_prefix:gsub("^/home/happens", "~")
  return without_home
end

local function get_base(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

local function get_process_part(tab)
  local title = tab.tab_title or tab.active_pane.title
  if title ~= nil and title:len() > 0 then
    return title
  end

  local base_process = get_base(tab.active_pane.foreground_process_name)
  if base_process == "zsh" then return nil end
  return base_process
end

local function get_tab_title(tab)
  local dir = format_dir(tab.active_pane.current_working_dir)
  local process = get_process_part(tab)

  local has_dir = dir ~= nil and dir:len() > 0
  local has_process = process ~= nil and process:len() > 0

  if has_dir and has_process then
    return dir .. " 󰅂 " .. process
  end

  if has_dir then return dir end
  return process
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

  local tab_title = get_tab_title(tab)
  append(result, { Text = "  " .. truncate_title(tab_title) .. "  " })

  return result
end)

-- config.debug_key_events = true

return config
