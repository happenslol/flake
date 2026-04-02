--- Custom highlight groups for diffv, matching delta's dark theme.
local M = {}

--- Define all diffv highlight groups.
--- Call on setup and on ColorScheme autocmd.
function M.setup()
  local set = vim.api.nvim_set_hl

  -- Line backgrounds (delta dark theme)
  set(0, "DiffvMinusBg", { bg = "#3f0001" })
  set(0, "DiffvMinusEmph", { bg = "#901011" })
  set(0, "DiffvPlusBg", { bg = "#002800" })
  set(0, "DiffvPlusEmph", { bg = "#006000" })

  -- Line number foreground colors (no background)
  set(0, "DiffvMinusNr", { fg = "#f07070" })
  set(0, "DiffvPlusNr", { fg = "#70c070" })

  -- Filler lines in diff mode (padding where the other side has content)
  set(0, "DiffvFiller", { bg = "NONE" })
end

return M
