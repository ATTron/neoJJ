--- Floating window popup engine.
--- Shows a Magit-style transient menu with single-keypress dispatch.
local M = {}

local config = require("neojj.config")

-- Track all open popup windows so we can close them externally
M._open_wins = {}

--- Open a popup menu.
---@param opts table { title: string, items: {{key, label, action}}, width?: int }
---@return integer win_id
function M.open(opts)
  local items = opts.items or {}
  local title = opts.title or "Menu"
  local width = opts.width or config.values.popup_width

  -- Build display lines
  local lines = { "  " .. title, "" }
  for _, item in ipairs(items) do
    local key_str = item[1]
    local label = item[2]
    table.insert(lines, "  " .. key_str .. "  " .. label)
  end
  table.insert(lines, "")
  table.insert(lines, "  <Esc>/q  close")

  local height = #lines
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = row,
    col = col,
    width = width,
    height = height,
    style = "minimal",
    border = config.values.float_border,
    title = " " .. title .. " ",
    title_pos = "center",
  })

  -- Highlights
  local ns = vim.api.nvim_create_namespace("neojj_popup")
  -- Title highlight
  vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
    end_col = #lines[1],
    hl_group = "NeoJJPopupTitle",
  })
  -- Key highlights
  for i, item in ipairs(items) do
    local line_idx = i + 1 -- offset for title + blank line
    vim.api.nvim_buf_set_extmark(buf, ns, line_idx, 2, {
      end_col = 2 + #item[1],
      hl_group = "NeoJJPopupKey",
    })
  end

  M._open_wins[win] = true

  -- Close helper
  local function close()
    M._open_wins[win] = nil
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  -- Auto-close when focus leaves the popup
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    once = true,
    callback = close,
  })

  -- Map keys
  for _, item in ipairs(items) do
    vim.keymap.set("n", item[1], function()
      close()
      item[3]() -- action
    end, { buffer = buf, nowait = true })
  end

  vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true })
  vim.keymap.set("n", "q", close, { buffer = buf, nowait = true })

  return win
end

--- Close all open popups.
function M.close_all()
  for win, _ in pairs(M._open_wins) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end
  M._open_wins = {}
end

return M
