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
