local M = {}

local groups = {
  NeoJJHeader = { link = "Title" },
  NeoJJChangeId = { link = "Identifier" },
  NeoJJCommitId = { link = "Constant" },
  NeoJJDescription = { link = "String" },
  NeoJJBookmark = { link = "Function" },
  NeoJJBookmarkRemote = { link = "Comment" },
  NeoJJTimestamp = { link = "Comment" },
  NeoJJFileModified = { link = "WarningMsg" },
  NeoJJFileAdded = { link = "DiffAdd" },
  NeoJJFileDeleted = { link = "DiffDelete" },
  NeoJJFileRenamed = { link = "DiffChange" },
  NeoJJFilePath = { link = "Directory" },
  NeoJJConflict = { link = "ErrorMsg" },
  NeoJJGraph = { link = "NonText" },
  NeoJJCurrent = { link = "CurSearch" },
  NeoJJPopupKey = { link = "Special" },
  NeoJJPopupAction = { link = "Normal" },
  NeoJJPopupTitle = { link = "Title" },
  NeoJJSectionHeader = { link = "Title" },
  NeoJJAlias = { link = "Type" },
  NeoJJAliasCmd = { link = "Comment" },
  NeoJJHelpKey = { link = "Special" },
  NeoJJHelpDesc = { link = "Comment" },
  NeoJJDim = { link = "Comment" },
  NeoJJEmpty = { link = "Comment" },
  NeoJJBookmarkUntracked = { link = "Comment" },
  NeoJJParent = { bold = true, italic = true, fg = "#888888" },
}

function M.setup()
  for name, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, name, opts)
  end
end

return M
