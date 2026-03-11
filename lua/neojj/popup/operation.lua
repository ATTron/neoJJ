--- Operation (undo/op log/restore) popup.
local M = {}

local popup = require("neojj.popup")
local commands = require("neojj.jj.commands")

function M.open()
  popup.open({
    title = "Operation",
    items = {
      { "u", "undo", function() commands.undo() end },
      { "l", "operation log", function() require("neojj.ui.oplog").open() end },
      { "R", "restore to operation", function()
        vim.ui.input({ prompt = "Operation ID: " }, function(op_id)
          if op_id then commands.op_restore(op_id) end
        end)
      end },
    },
  })
end

return M
