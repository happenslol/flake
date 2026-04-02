--- Diff engine dispatcher.
--- All diff operations go through this module. The active engine is selected
--- from config and can be changed at runtime.
---
--- Every engine module must implement:
---   diff(old_text, new_text, opts?) → diffv.DiffResult
---   word_diff(old_line, new_line) → { old_ranges: number[][], new_ranges: number[][] }
---   line_distance(old_line, new_line) → number (0 = identical, 1 = completely different)
local M = {}

local engines = {
  line = "diffv.diff.line",
  semantic = "diffv.diff.semantic",
}

---@return table the active engine module
local function engine()
  local name = require("diffv.config").values.diff_engine or "line"
  local mod_name = engines[name]
  if not mod_name then
    vim.notify("diffv: unknown diff engine '" .. name .. "', falling back to line", vim.log.levels.WARN)
    mod_name = engines.line
  end
  return require(mod_name)
end

--- Register a custom engine module.
---@param name string engine name for config
---@param module_path string lua module path (e.g. "my_plugin.diff_engine")
function M.register_engine(name, module_path)
  engines[name] = module_path
end

--- Compute a diff between two strings.
---@param old_text string
---@param new_text string
---@param opts? table engine-specific options
---@return diffv.DiffResult
function M.diff(old_text, new_text, opts)
  return engine().diff(old_text, new_text, opts)
end

--- Compute word-level diff within a pair of changed lines.
--- Returns column ranges (0-indexed, end-exclusive) of changed regions.
---@param old_line string
---@param new_line string
---@return { old_ranges: number[][], new_ranges: number[][] }
function M.word_diff(old_line, new_line)
  return engine().word_diff(old_line, new_line)
end

--- Compute the edit distance ratio between two lines.
--- Returns 0 for identical lines, 1 for completely different lines.
---@param old_line string
---@param new_line string
---@return number distance 0-1
function M.line_distance(old_line, new_line)
  return engine().line_distance(old_line, new_line)
end

return M
