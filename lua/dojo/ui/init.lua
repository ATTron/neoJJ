--- Buffer creation and singleton management.
local M = {}

local config = require("dojo.config")

-- Track singleton buffers by name
local singletons = {}

--- Create or reuse a singleton buffer for the given name.
---@param name string buffer name (e.g., "dojo://status")
---@return integer bufnr
function M.get_or_create(name)
  local existing = singletons[name]
  if existing and vim.api.nvim_buf_is_valid(existing) then
    return existing
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "dojo"

  singletons[name] = buf

  -- Clean up on wipe
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      singletons[name] = nil
    end,
  })

  return buf
end

--- Open buffer in the current window or a new split.
---@param buf integer
---@param split string|nil "v" for vertical, "h" for horizontal, nil for current window
function M.open(buf, split)
  if split == "v" then
    vim.cmd("vsplit")
    vim.cmd("vertical resize " .. config.values.split_width)
  elseif split == "h" then
    vim.cmd("botright split")
    vim.cmd("resize " .. config.values.split_height)
  end
  vim.api.nvim_set_current_buf(buf)
end

--- Close a buffer by name.
---@param name string
function M.close(name)
  local buf = singletons[name]
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  singletons[name] = nil
end

--- Get the buffer number for a singleton.
---@param name string
---@return integer|nil
function M.get_buf(name)
  local buf = singletons[name]
  if buf and vim.api.nvim_buf_is_valid(buf) then
    return buf
  end
  return nil
end

return M
