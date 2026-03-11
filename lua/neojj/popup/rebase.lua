--- Rebase popup.
local M = {}

local popup = require("neojj.popup")
local commands = require("neojj.jj.commands")
local status = require("neojj.ui.status")
local config = require("neojj.config")

function M.open()
  local meta = status.cursor_meta()
  local rev = meta and meta.change_id or nil
  local default_dest = config.values.default_rebase_dest

  popup.open({
    title = "Rebase",
    items = {
      { "d", "rebase onto destination", function()
        vim.ui.input({ prompt = "Destination: " }, function(dest)
          if dest then commands.rebase_dest(dest) end
        end)
      end },
      { "s", "rebase source tree", function()
        local source = rev or "@"
        vim.ui.input({ prompt = "Destination: " }, function(dest)
          if dest then commands.rebase_source(source, dest) end
        end)
      end },
      { "b", "rebase branch", function()
        vim.ui.input({ prompt = "Branch revision: " }, function(branch)
          if not branch then return end
          vim.ui.input({ prompt = "Destination: " }, function(dest)
            if dest then commands.rebase_branch(branch, dest) end
          end)
        end)
      end },
      { "m", "rebase onto " .. default_dest, function()
        commands.rebase_dest(default_dest)
      end },
    },
  })
end

return M
