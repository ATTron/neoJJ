local M = {}

M.defaults = {
  jj_binary = "jj",
  log_limit = 15,
  float_border = "rounded",
  popup_width = 60,
  -- How to open the status buffer: "current", "split", or "vsplit"
  open_mode = "current",
  -- Size of the split when using split/vsplit
  split_width = 80,
  split_height = 20,
  -- Default remote for push/track/fetch
  default_remote = "origin",
  -- Default rebase destination (used by "rebase onto default" shortcut)
  default_rebase_dest = "main@origin",
  -- Enable nerd font icons (requires a patched font, optionally nvim-web-devicons)
  icons = false,
}

M.values = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.values = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
