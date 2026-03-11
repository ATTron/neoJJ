--- Operation (undo/op log/restore) popup.
local M = {}

local popup = require("dojo.popup")
local commands = require("dojo.jj.commands")

function M.open()
  popup.open({
    title = "Operation",
    items = {
      { "u", "undo", function() commands.undo() end },
      { "l", "operation log", function() require("dojo.ui.oplog").open() end },
      { "R", "restore to operation", function()
        vim.ui.input({ prompt = "Operation ID: " }, function(op_id)
          if op_id then commands.op_restore(op_id) end
        end)
      end },
    },
  })
end

return M
