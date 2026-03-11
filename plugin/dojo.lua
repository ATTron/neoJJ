--- Plugin entry point — registers user commands.
if vim.g.loaded_dojo then return end
vim.g.loaded_dojo = true

vim.api.nvim_create_user_command("Dojo", function()
  require("dojo").open()
end, { desc = "Open dojo.nvim status buffer" })

vim.api.nvim_create_user_command("DojoLog", function()
  require("dojo").log()
end, { desc = "Open dojo.nvim log view" })

vim.api.nvim_create_user_command("DojoOpLog", function()
  require("dojo").oplog()
end, { desc = "Open dojo.nvim operation log" })

vim.api.nvim_create_user_command("DojoDebug", function()
  require("dojo.log").open()
end, { desc = "Open dojo.nvim debug log" })

vim.api.nvim_create_user_command("DojoDebugClear", function()
  require("dojo.log").clear()
end, { desc = "Clear dojo.nvim debug log" })
