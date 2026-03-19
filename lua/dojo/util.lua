--- Small utility helpers for dojo.
local M = {}

--- Prompt the user for yes/no confirmation before running `fn`.
---@param prompt string
---@param fn function
function M.confirm(prompt, fn)
  vim.ui.select({ "Yes", "No" }, { prompt = prompt }, function(choice)
    if choice == "Yes" then fn() end
  end)
end

return M
