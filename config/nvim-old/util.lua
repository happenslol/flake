local M = {}

function M.bootstrap_packer()
  local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"

  if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
    vim.cmd("!git clone git@github.com:wbthomason/packer.nvim " .. install_path)
    vim.cmd "packadd packer.nvim"
  end
end

local function assign_map(obj, map)
  for k, v in pairs(map) do obj[k] = v end
end

function M.set_global(map) assign_map(vim.g, map) end
function M.set_opt(map) assign_map(vim.opt, map) end

function M.cmd(cmds)
  for _, c in pairs(cmds) do vim.cmd(c) end
end

function M.keys(tbl)
  local tbl_keys = {}
  for key, _ in pairs(tbl) do
    table.insert(tbl_keys, key)
  end

  return tbl_keys
end

function M.sign_define(hl, text)
  if type(hl) == "string" then
    vim.fn.sign_define(hl, { text = text, texthl = hl })
    return
  end

  for _, arg in pairs(hl) do
    M.sign_define(arg[1], arg[2])
  end
end

function M.apply_keymap(map_table, extra_opts)
  for mode, maps in pairs(map_table) do
    for keymap, options in pairs(maps) do
      if options then
        local cmd = options

        local keymap_opts = { silent = true }
        if type(extra_opts) == "table" then
          keymap_opts = vim.tbl_deep_extend("force", keymap_opts, extra_opts)
        end

        if type(options) == "table" then
          cmd = options[1]
          keymap_opts = vim.tbl_deep_extend("force", keymap_opts, options)
          keymap_opts[1] = nil
        elseif type(options) == "string" then
          cmd = options
        end

        vim.keymap.set(mode, keymap, cmd, keymap_opts)
      end
    end
  end
end

function M.create_keymap()
  return { i = {}, n = {}, v = {}, t = {} }
end

return M
