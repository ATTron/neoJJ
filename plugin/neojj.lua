--- Plugin entry point — registers user commands.
if vim.g.loaded_neojj then return end
vim.g.loaded_neojj = true

vim.api.nvim_create_user_command("NeoJJ", function()
  require("neojj").open()
end, { desc = "Open neoJJ status buffer" })

vim.api.nvim_create_user_command("NeoJJLog", function()
  require("neojj").log()
end, { desc = "Open neoJJ log view" })

vim.api.nvim_create_user_command("NeoJJOpLog", function()
  require("neojj").oplog()
end, { desc = "Open neoJJ operation log" })

vim.api.nvim_create_user_command("NeoJJDebug", function()
  require("neojj.log").open()
end, { desc = "Open neoJJ debug log" })

vim.api.nvim_create_user_command("NeoJJDebugClear", function()
  require("neojj.log").clear()
end, { desc = "Clear neoJJ debug log" })
