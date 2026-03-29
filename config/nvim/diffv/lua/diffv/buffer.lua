--- Scratch buffer lifecycle management for diffv.
local M = {}

--- Active diffv buffers (tracked for cleanup).
---@type number[]
M.buffers = {}

--- Create a scratch buffer configured for displaying diff content.
---@param filetype? string filetype for syntax highlighting
---@param name? string buffer name
---@return number buf buffer handle
function M.create(filetype, name)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = true

  if filetype then
    vim.bo[buf].filetype = filetype
  end

  if name then
    vim.api.nvim_buf_set_name(buf, name)
  end

  M.buffers[#M.buffers + 1] = buf

  -- Auto-remove from tracking when wiped
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      for i, b in ipairs(M.buffers) do
        if b == buf then
          table.remove(M.buffers, i)
          break
        end
      end
    end,
  })

  return buf
end

--- Set buffer lines, temporarily enabling modifiable.
---@param buf number
---@param lines string[]
function M.set_lines(buf, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

--- Wipe all tracked diffv buffers.
function M.cleanup()
  -- Copy the list since wipeout autocmd modifies M.buffers
  local bufs = vim.list_extend({}, M.buffers)
  for _, buf in ipairs(bufs) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  M.buffers = {}
end

return M
