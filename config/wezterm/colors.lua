return {
  foreground = "#eeffff",
  background = "#212121",

  cursor_bg = "#eeffff",
  cursor_fg = "#212121",
  cursor_border = "#a5a5a5",

  selection_fg = "#eeffff",
  selection_bg = "#444444",

  split = "#444444",

  ansi = {
    "#2b2b2b", -- Black
    "#f07178", -- Maroon
    "#c3e88d", -- Green
    "#ffcb6b", -- Olive
    "#82aaff", -- Navy
    "#c792ea", -- Purple
    "#89ddff", -- Teal
    "#ddeeee", -- Silver
  },

  brights = {
    "#404040", -- Grey
    "#ff8b92", -- Red
    "#ddffa7", -- Lime
    "#ffe585", -- Yellow
    "#9cc4ff", -- Blue
    "#e1acff", -- Fuchsia
    "#a3f7ff", -- Aqua
    "#ffffff", -- White
  },

  compose_cursor = "#f78c6c",

  copy_mode_active_highlight_bg = { AnsiColor = "Grey" },
  copy_mode_active_highlight_fg = { AnsiColor = "Silver" },
  copy_mode_inactive_highlight_bg = { AnsiColor = "Green" },
  copy_mode_inactive_highlight_fg = { AnsiColor = "White" },

  quick_select_label_bg = { AnsiColor = "Red" },
  quick_select_label_fg = { AnsiColor = "Black" },
  quick_select_match_bg = { AnsiColor = "Yellow" },
  quick_select_match_fg = { AnsiColor = "Black" },

  tab_bar = {
    background = "#212121",
    active_tab = {
      bg_color = "#82aaff",
      fg_color = "#212121",
      intensity = "Bold",
      underline = "None",
      italic = false,
      strikethrough = false,
    },
    inactive_tab = {
      bg_color = "#212121",
      fg_color = "#eeffff",
      intensity = "Normal",
      underline = "None",
      italic = false,
      strikethrough = false,
    },
    inactive_tab_hover = {
      bg_color = "#212121",
      fg_color = "#eeffff",
      intensity = "Bold",
      underline = "None",
      italic = false,
      strikethrough = false,
    },

    new_tab = {
      bg_color = "#212121",
      fg_color = "#212121",
    },

    new_tab_hover = {
      bg_color = "#212121",
      fg_color = "#212121",
    },
  },
}
