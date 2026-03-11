local M = {}

local groups = {
  DojoHeader = { link = "Title" },
  DojoChangeId = { link = "Identifier" },
  DojoCommitId = { link = "Constant" },
  DojoDescription = { link = "String" },
  DojoBookmark = { link = "Function" },
  DojoBookmarkRemote = { link = "Comment" },
  DojoTimestamp = { link = "Comment" },
  DojoFileModified = { link = "WarningMsg" },
  DojoFileAdded = { link = "Added" },
  DojoFileDeleted = { link = "Removed" },
  DojoFileRenamed = { link = "Changed" },
  DojoFilePath = { link = "Directory" },
  DojoConflict = { link = "ErrorMsg" },
  DojoGraph = { link = "NonText" },
  DojoCurrent = { link = "CurSearch" },
  DojoPopupKey = { link = "Special" },
  DojoPopupAction = { link = "Normal" },
  DojoPopupTitle = { link = "Title" },
  DojoSectionHeader = { link = "Title" },
  DojoAlias = { link = "Type" },
  DojoAliasCmd = { link = "Comment" },
  DojoHelpKey = { link = "Special" },
  DojoHelpDesc = { link = "Comment" },
  DojoDim = { link = "Comment" },
  DojoEmpty = { link = "Comment" },
  DojoBookmarkUntracked = { link = "Comment" },
  DojoParent = { bold = true, italic = true, fg = "#888888" },
}

function M.setup()
  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

return M
