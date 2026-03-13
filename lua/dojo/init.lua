--- dojo.nvim — Magit-inspired Neovim interface for jj (Jujutsu).
local M = {}

--- Setup dojo.nvim with user options.
---@param opts table|nil
function M.setup(opts)
  require("dojo.config").setup(opts)
  require("dojo.hl").setup()
end

--- Open the status buffer.
function M.open()
  require("dojo.ui.status").open()
end

--- Close the status buffer.
function M.close()
  require("dojo.ui.status").close()
end

--- Refresh the status buffer.
function M.refresh()
  require("dojo.ui.status").refresh()
end

--- Open the full log view.
function M.log()
  require("dojo.ui.log").open()
end

--- Open the operation log view.
function M.oplog()
  require("dojo.ui.oplog").open()
end

return M
