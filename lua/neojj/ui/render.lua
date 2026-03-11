--- Line-based renderer with extmark highlights.
local M = {}

local ns = vim.api.nvim_create_namespace("neojj")

--- Render lines into a buffer, replacing all content.
--- Each line can be a string or a table { text = "...", highlights = {{group, col_start, col_end}} }.
---@param buf integer
---@param lines table[]
---@param line_meta table|nil metadata table to populate (indexed by 1-based line number)
function M.render(buf, lines, line_meta)
  vim.bo[buf].modifiable = true

  -- Build plain text lines
  local text_lines = {}
  for _, line in ipairs(lines) do
    if type(line) == "string" then
      table.insert(text_lines, line)
    else
      table.insert(text_lines, line.text or "")
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, text_lines)

  -- Clear old extmarks
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  -- Apply highlights
  for i, line in ipairs(lines) do
    if type(line) == "table" and line.highlights then
      local line_len = #(text_lines[i] or "")
      for _, hl in ipairs(line.highlights) do
        local col_start = math.min(hl[2], line_len)
        local col_end = math.min(hl[3], line_len)
        if col_start < col_end then
          vim.api.nvim_buf_set_extmark(buf, ns, i - 1, col_start, {
            end_col = col_end,
            hl_group = hl[1],
          })
        end
      end
    end
    -- Store metadata
    if line_meta and type(line) == "table" and line.meta then
      line_meta[i] = line.meta
    end
  end

  vim.bo[buf].modifiable = false
end

--- Get metadata for the line under the cursor.
---@param line_meta table
---@return table|nil
function M.get_cursor_meta(line_meta)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  return line_meta[row]
end

--- Navigate to the next/prev line that has metadata.
---@param line_meta table
---@param direction integer 1 for next, -1 for prev
---@param filter fun(meta: table): boolean|nil optional filter (return true to land on this line)
function M.move_to_meta(line_meta, direction, filter)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local max = vim.api.nvim_buf_line_count(0)
  local next_row = row + direction
  while next_row >= 1 and next_row <= max do
    local meta = line_meta[next_row]
    if meta and (not filter or filter(meta)) then
      vim.api.nvim_win_set_cursor(0, { next_row, 0 })
      return
    end
    next_row = next_row + direction
  end
end

--- Map a key in a buffer (convenience helper for view modules).
---@param buf integer
---@param key string
---@param fn function
function M.map(buf, key, fn)
  vim.keymap.set("n", key, fn, { buffer = buf, nowait = true })
end

return M
