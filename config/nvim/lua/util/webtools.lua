-- Which JS/TS toolchains a project has configured, resolved by walking up from a
-- directory looking for each tool's marker files (or package.json keys).
--
-- Shared by the conform.nvim formatting strategy and the denols LSP config, so
-- both agree on which tool owns formatting and linting for a given project.

---@class util.webtools
local M = {}

-- Marker files (and package.json keys) that identify each tool's config.
local detectors = {
  deno = { files = { "deno.json", "deno.jsonc", "deno.lock" } },
  oxfmt = { files = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts" } },
  oxlint = { files = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts" } },
  biome = { files = { "biome.json", "biome.jsonc", ".biome.json", ".biome.jsonc" } },
  prettier = {
    pkg_key = "prettier",
    files = {
      ".prettierrc",
      ".prettierrc.json",
      ".prettierrc.yml",
      ".prettierrc.yaml",
      ".prettierrc.json5",
      ".prettierrc.js",
      ".prettierrc.cjs",
      ".prettierrc.mjs",
      ".prettierrc.ts",
      ".prettierrc.toml",
      "prettier.config.js",
      "prettier.config.cjs",
      "prettier.config.mjs",
      "prettier.config.ts",
    },
  },
  eslint = {
    pkg_key = "eslintConfig",
    files = {
      ".eslintrc",
      ".eslintrc.js",
      ".eslintrc.cjs",
      ".eslintrc.json",
      ".eslintrc.yaml",
      ".eslintrc.yml",
      "eslint.config.js",
      "eslint.config.mjs",
      "eslint.config.cjs",
      "eslint.config.ts",
      "eslint.config.mts",
    },
  },
}

M.detectors = detectors

-- Whether `tool`'s config exists above `dir`, cached per (tool, dir).
local cache = {}

---@param tool string
---@param dir? string defaults to the current working directory
---@return boolean
function M.detect(tool, dir)
  dir = (type(dir) == "string" and dir ~= "") and dir or vim.fn.getcwd()
  local key = tool .. "\0" .. dir
  if cache[key] == nil then
    local spec = detectors[tool]
    cache[key] = vim.fs.root(dir, function(name, path)
      if vim.tbl_contains(spec.files, name) then
        return true
      end
      if spec.pkg_key and name == "package.json" then
        local ok, data = pcall(function()
          return vim.json.decode(table.concat(vim.fn.readfile(vim.fs.joinpath(path, name)), "\n"))
        end)
        return (ok and type(data) == "table" and data[spec.pkg_key] ~= nil) or false
      end
      return false
    end) ~= nil
  end
  return cache[key]
end

-- True if any of the tools we care about is configured in this project.
---@param dir? string
---@return boolean
function M.any_config(dir)
  for tool in pairs(detectors) do
    if M.detect(tool, dir) then
      return true
    end
  end
  return false
end

-- oxfmt/oxlint replace deno's formatter and linter when either is configured.
---@param dir? string
---@return boolean
function M.ox_overrides_deno(dir)
  return M.detect("oxfmt", dir) or M.detect("oxlint", dir)
end

return M
