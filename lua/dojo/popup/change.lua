--- Change popup: new, describe, squash, split, abandon, edit, duplicate.
local M = {}

local popup = require("dojo.popup")
local commands = require("dojo.jj.commands")
local status = require("dojo.ui.status")

function M.open()
  local meta = status.cursor_meta()
  local rev = meta and meta.change_id or nil

  popup.open({
    title = "Change",
    items = {
      { "n", "new change", function() commands.new_change() end },
      { "d", "describe", function()
        require("dojo.ui.describe").open(rev)
      end },
      { "s", "squash into parent", function() commands.squash() end },
      { "S", "split (interactive)", function() commands.split() end },
      { "a", "abandon" .. (rev and (" " .. rev) or ""), function()
        local target = rev or "@"
        vim.ui.select({ "Yes", "No" }, { prompt = "Abandon " .. target .. "?" }, function(choice)
          if choice == "Yes" then commands.abandon(target) end
        end)
      end },
      { "e", "edit" .. (rev and (" " .. rev) or ""), function()
        if rev then
          commands.edit(rev)
        else
          vim.ui.input({ prompt = "Edit revision: " }, function(r)
            if r then commands.edit(r) end
          end)
        end
      end },
      { "D", "duplicate" .. (rev and (" " .. rev) or ""), function()
        commands.duplicate(rev)
      end },
    },
  })
end

return M
