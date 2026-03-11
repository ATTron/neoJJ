--- Bookmark popup.
local M = {}

local popup = require("dojo.popup")
local commands = require("dojo.jj.commands")
local status = require("dojo.ui.status")
local config = require("dojo.config")

function M.open()
  local meta = status.cursor_meta()
  local rev = meta and meta.change_id or nil
  local remote = config.values.default_remote

  popup.open({
    title = "Bookmark",
    items = {
      { "s", "set bookmark (create or update)", function()
        vim.ui.input({ prompt = "Bookmark name: " }, function(name)
          if name then commands.bookmark_set(name, rev) end
        end)
      end },
      { "c", "create bookmark at @", function()
        vim.ui.input({ prompt = "New bookmark name: " }, function(name)
          if name then commands.bookmark_create(name) end
        end)
      end },
      { "t", "track remote bookmark", function()
        vim.ui.input({
          prompt = "Bookmark to track (e.g. main@" .. remote .. "): ",
        }, function(bookmark)
          if not bookmark then return end
          local name, r = bookmark:match("^(.+)@(.+)$")
          if not name then
            name = bookmark
            r = remote
          end
          commands.bookmark_track(name, r)
        end)
      end },
      { "d", "delete bookmark", function()
        vim.ui.input({ prompt = "Delete bookmark: " }, function(name)
          if name then commands.bookmark_delete(name) end
        end)
      end },
      { "a", "advance bookmark", function()
        vim.ui.input({ prompt = "Bookmark name: " }, function(name)
          if name then commands.bookmark_advance(name) end
        end)
      end },
      { "m", "move bookmark", function()
        vim.ui.input({ prompt = "Bookmark name: " }, function(name)
          if not name then return end
          vim.ui.input({ prompt = "Move to (revision): " }, function(dest)
            if dest then commands.bookmark_move(name, dest) end
          end)
        end)
      end },
      { "e", "edit (switch to bookmark)", function()
        local name = meta and meta.name or nil
        if name then
          commands.edit(name)
        else
          vim.ui.input({ prompt = "Bookmark to switch to: " }, function(input)
            if input then commands.edit(input) end
          end)
        end
      end },
      { "l", "list bookmarks", function()
        -- Jump to the Bookmarks section in the status buffer
        local sbuf = status.get_buf()
        if not sbuf then
          vim.notify("Status buffer not open", vim.log.levels.WARN)
          return
        end
        local lines = vim.api.nvim_buf_get_lines(sbuf, 0, -1, false)
        for i, line in ipairs(lines) do
          if line:match("Bookmarks") and line:match("^[▸▾]") then
            -- Find the window showing the status buffer
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_get_buf(win) == sbuf then
                vim.api.nvim_win_set_cursor(win, { i, 0 })
                return
              end
            end
          end
        end
        vim.notify("No Bookmarks section found", vim.log.levels.WARN)
      end },
    },
  })
end

return M
