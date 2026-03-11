--- neoJJ — Magit-inspired Neovim interface for jj (Jujutsu).
local M = {}

--- Setup neoJJ with user options.
---@param opts table|nil
function M.setup(opts)
  require("neojj.config").setup(opts)
  require("neojj.hl").setup()

  -- Pre-fetch aliases in the background
  require("neojj.jj.aliases").fetch(function() end)
end

--- Open the status buffer.
function M.open()
  require("neojj.ui.status").open()
end

--- Close the status buffer.
function M.close()
  require("neojj.ui.status").close()
end

--- Refresh the status buffer.
function M.refresh()
  require("neojj.ui.status").refresh()
end

--- Open the full log view.
function M.log()
  require("neojj.ui.log").open()
end

--- Open the operation log view.
function M.oplog()
  require("neojj.ui.oplog").open()
end

return M
