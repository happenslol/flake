local M = {}
local w = require("wezterm")
local act = w.action

M.leader = { key = "e", mods = "CTRL", timeout_milliseconds = 5000 }

local function leader(key, action, mods)
  local mods_with_leader = "LEADER"
  if mods ~= nil then
    mods_with_leader = mods_with_leader .. "|" .. mods
  end

  return { key = key, mods = mods_with_leader, action = action }
end

M.keys = {
  leader("c", act.SpawnTab("CurrentPaneDomain")),
  leader("x", act.CloseCurrentPane({ confirm = false })),
  leader("o", act.SplitVertical({ domain = "CurrentPaneDomain" })),
  leader("u", act.SplitHorizontal({ domain = "CurrentPaneDomain" })),

  leader("h", act.ActivatePaneDirection("Left")),
  leader("j", act.ActivatePaneDirection("Down")),
  leader("k", act.ActivatePaneDirection("Up")),
  leader("l", act.ActivatePaneDirection("Right")),

  leader("h", act.MoveTabRelative(-1), "CTRL"),
  leader("l", act.MoveTabRelative(1), "CTRL"),

  leader("v", act.ActivateCopyMode),
  leader("v", act.QuickSelect, "CTRL"),

  { key = "D", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay },
  {
    key = "L",
    mods = "CTRL|SHIFT",
    action = act.Multiple({
      act.ClearScrollback("ScrollbackAndViewport"),
      act.SendKey({ key = "L", mods = "CTRL" }),
    }),
  },

  { key = "+", mods = "SHIFT|CTRL", action = act.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = act.DecreaseFontSize },
  { key = "=", mods = "CTRL", action = act.ResetFontSize },
  { key = "R", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
  { key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

  { key = "Escape", action = act.Multiple({ act.ClearSelection, act.SendKey({ key = "Escape" }) }) },
}

for i = 1, 9 do
  M.keys[#M.keys + 1] = { key = tostring(i), mods = "ALT", action = act.ActivateTab(i - 1) }
end

M.key_tables = {}

local close_copy_mode = act.Multiple({ act.CopyMode("ClearPattern"), act.CopyMode("Close"), act.ClearSelection })

M.key_tables.copy_mode = {
  { key = "h", action = act.CopyMode("MoveLeft") },
  { key = "j", action = act.CopyMode("MoveDown") },
  { key = "k", action = act.CopyMode("MoveUp") },
  { key = "l", action = act.CopyMode("MoveRight") },

  { key = "Escape", action = close_copy_mode },
  { key = "q", action = close_copy_mode },
  { key = "c", mods = "CTRL", action = close_copy_mode },
  { key = "$", mods = "SHIFT", action = act.CopyMode("MoveToEndOfLineContent") },
  { key = "0", action = act.CopyMode("MoveToStartOfLine") },
  { key = "^", mods = "SHIFT", action = act.CopyMode("MoveToStartOfLineContent") },

  { key = "G", mods = "SHIFT", action = act.CopyMode("MoveToScrollbackBottom") },
  { key = "g", action = act.CopyMode("MoveToScrollbackTop") },
  { key = "f", mods = "SHIFT", action = act.CopyMode({ JumpForward = { prev_char = false } }) },
  { key = "F", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = false } }) },
  { key = "t", mods = "SHIFT", action = act.CopyMode({ JumpForward = { prev_char = true } }) },
  { key = "T", mods = "SHIFT", action = act.CopyMode({ JumpBackward = { prev_char = true } }) },

  { key = "v", action = act.CopyMode({ SetSelectionMode = "Cell" }) },
  { key = "V", mods = "SHIFT", action = act.CopyMode({ SetSelectionMode = "Line" }) },
  { key = "v", mods = "CTRL", action = act.CopyMode({ SetSelectionMode = "Block" }) },

  { key = "w", action = act.CopyMode("MoveForwardWord") },
  { key = "W", mods = "SHIFT", action = act.CopyMode("MoveForwardWord") },
  { key = "b", action = act.CopyMode("MoveBackwardWord") },
  { key = "b", mods = "SHIFT", action = act.CopyMode("MoveBackwardWord") },
  { key = "e", action = act.CopyMode("MoveForwardWordEnd") },
  { key = "e", mods = "SHIFT", action = act.CopyMode("MoveForwardWordEnd") },

  {
    key = "y",
    action = act.Multiple({
      act.CopyTo("Clipboard"),
      act.ClearSelection,
      act.CopyMode("ClearSelectionMode"),
    }),
  },
  {
    key = "Enter",
    action = act.Multiple({
      act.CopyTo("Clipboard"),
      act.ClearSelection,
      act.CopyMode("Close"),
    }),
  },

  { key = "PageUp", action = act.CopyMode("PageUp") },
  { key = "PageDown", action = act.CopyMode("PageDown") },
  { key = "End", action = act.CopyMode("MoveToEndOfLineContent") },
  { key = "Home", action = act.CopyMode("MoveToStartOfLine") },
  { key = "/", action = act.Multiple({ act.CopyMode("ClearSelectionMode"), act.CopyMode("EditPattern") }) },
  { key = "n", action = act.CopyMode("NextMatch") },
  { key = "N", action = act.CopyMode("PriorMatch") },
}

M.key_tables.search_mode = {
  { key = "Enter", action = act.CopyMode("AcceptPattern") },
  { key = "Escape", action = act.Multiple({ act.CopyMode("ClearPattern"), act.CopyMode("AcceptPattern") }) },
}

return M
