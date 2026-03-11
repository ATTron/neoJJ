--- Diff viewer buffer.
local M = {}

local jj = require("dojo.jj")
local ui = require("dojo.ui")

local BUF_NAME = "dojo://diff"

--- Show diff for a revision, optionally filtered to a single file.
---@param rev string|nil
---@param path string|nil
function M.show(rev, path)
  local args = { "diff" }
  if rev then vim.list_extend(args, { "-r", rev }) end
  if path then table.insert(args, path) end

  jj.run(args, {}, function(result)
    if result.code ~= 0 then
      vim.notify("jj diff: " .. vim.trim(result.stderr), vim.log.levels.ERROR)
      return
    end
    M._display(result.stdout)
  end)
end

--- Show diff for a specific file (convenience wrapper).
---@param path string
---@param rev string|nil
function M.show_file(path, rev)
  if not path then return end
  M.show(rev, path)
end

--- Display diff output in a buffer.
---@param content string
function M._display(content)
  local buf = ui.get_or_create(BUF_NAME)

  vim.cmd("botright split")
  vim.api.nvim_set_current_buf(buf)

  local lines = vim.split(content, "\n")
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "diff"

  local function close()
    vim.api.nvim_win_close(0, true)
  end
  vim.keymap.set("n", "<BS>", close, { buffer = buf })
  vim.keymap.set("n", "q", close, { buffer = buf })
end

return M
