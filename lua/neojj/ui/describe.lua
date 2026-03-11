--- Scratch buffer for editing change descriptions.
--- Opens a small buffer pre-filled with the current description.
--- :w saves it via `jj describe`, :q! cancels.
local M = {}

local jj = require("neojj.jj")
local commands = require("neojj.jj.commands")

--- Open the describe editor for a revision.
---@param rev string|nil revision to describe (nil = working copy "@")
function M.open(rev)
  rev = rev or "@"

  -- Fetch the current description
  jj.run({ "log", "--no-graph", "-T", "description", "-r", rev }, {}, function(result)
    if result.code ~= 0 then
      vim.notify("jj: " .. vim.trim(result.stderr), vim.log.levels.ERROR)
      return
    end

    local current = result.stdout
    -- Strip trailing newline that jj adds
    if current:sub(-1) == "\n" then
      current = current:sub(1, -2)
    end

    M._open_editor(rev, current)
  end)
end

--- Open the scratch buffer with the current description.
---@param rev string
---@param current_desc string
function M._open_editor(rev, current_desc)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "acwrite" -- lets us intercept :w
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_name(buf, "neojj://describe")

  -- Fill with current description
  local lines = vim.split(current_desc, "\n")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Open as a small bottom split
  vim.cmd("botright split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_win_set_height(win, math.max(#lines + 2, 5))

  -- Place cursor at end of first line for quick editing
  local first_line_len = #(lines[1] or "")
  pcall(vim.api.nvim_win_set_cursor, win, { 1, first_line_len })

  -- Placeholder virtual text when empty
  local ns = vim.api.nvim_create_namespace("neojj_describe")
  local is_empty = current_desc == "" or current_desc == "(no description set)"

  local function update_placeholder()
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local all_empty = #buf_lines == 0 or (#buf_lines == 1 and buf_lines[1] == "")
    if all_empty then
      vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
        virt_text = { { "Enter description (:w to save, q to cancel)", "Comment" } },
        virt_text_pos = "overlay",
      })
    end
  end

  if is_empty then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
    update_placeholder()
    vim.cmd("startinsert")
  end

  -- Update placeholder as you type
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    buffer = buf,
    callback = update_placeholder,
  })

  -- Save handler: :w runs jj describe
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local new_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local message = table.concat(new_lines, "\n")

      -- Trim trailing whitespace
      message = message:gsub("%s+$", "")

      if message == "" then
        vim.notify("Description is empty, not saving", vim.log.levels.WARN)
        return
      end

      commands.describe(message, rev, function(result)
        if result.code == 0 then
          -- Mark as saved and close
          vim.bo[buf].modified = false
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
          end
        end
      end)
    end,
  })

  -- q in normal mode closes without saving
  vim.keymap.set("n", "q", function()
    vim.bo[buf].modified = false
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf })
end

return M
