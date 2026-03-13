--- Diff viewer buffer.
local M = {}

local jj = require("dojo.jj")
local ui = require("dojo.ui")

local BUF_NAME = "dojo://diff"

--- Quote a file path for use in a jj fileset expression.
--- Wrapping in double quotes prevents special characters (parentheses,
--- brackets, braces, etc.) from being interpreted as fileset operators.
---@param p string
---@return string
local function fileset_quote(p)
  return '"' .. p:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
end

--- Close any existing diff window.
local function close_existing()
  local buf = ui.get_buf(BUF_NAME)
  if not buf then return end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_win_close(win, true)
      break
    end
  end
end

--- Show diff for a revision, optionally filtered to a single file.
---@param rev string|nil
---@param path string|nil
function M.show(rev, path)
  local args = { "diff", "--git" }
  if rev then vim.list_extend(args, { "-r", rev }) end
  if path then table.insert(args, fileset_quote(path)) end

  jj.run(args, {}, function(result)
    if result.code ~= 0 then
      vim.notify("jj diff: " .. vim.trim(result.stderr), vim.log.levels.ERROR)
      return
    end
    if vim.trim(result.stdout) == "" then
      vim.notify("No changes to display", vim.log.levels.INFO)
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
  close_existing()

  local buf = ui.get_or_create(BUF_NAME)
  local lines = vim.split(content, "\n")

  -- Open split and show buffer
  vim.cmd("botright split")
  vim.api.nvim_set_current_buf(buf)

  -- Standard unified diff format — Neovim's built-in diff syntax
  -- handles +/- lines, @@ hunks, and --- +++ headers natively.
  vim.bo[buf].filetype = "diff"

  -- Set content after filetype to survive any autocmds
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local function close()
    vim.api.nvim_win_close(0, true)
  end
  vim.keymap.set("n", "<BS>", close, { buffer = buf })
  vim.keymap.set("n", "q", close, { buffer = buf })
end

return M
