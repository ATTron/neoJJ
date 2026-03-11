--- High-level jj operations.
--- Each function wraps a jj CLI call and triggers a status refresh on success.
local M = {}

local jj = require("neojj.jj")
local config = require("neojj.config")

--- Callback helper: notify on error, refresh status on success.
local function with_refresh(on_done)
  return function(result)
    if result.code ~= 0 then
      vim.notify("jj: " .. vim.trim(result.stderr), vim.log.levels.ERROR)
    end
    if on_done then on_done(result) end
    local status = require("neojj.ui.status")
    if status.is_open() then status.refresh() end
  end
end

--- Open a jj command in a terminal split, refreshing status on close.
---@param args string[] jj subcommand args (e.g. {"split"})
function M.open_in_terminal(args)
  local escaped = {}
  for _, arg in ipairs(args) do
    table.insert(escaped, vim.fn.shellescape(arg))
  end
  local cmd = config.values.jj_binary .. " " .. table.concat(escaped, " ")
  vim.cmd("botright split | terminal " .. cmd)

  local term_buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = term_buf,
    once = true,
    callback = function()
      -- Auto-close the terminal buffer on success
      if vim.v.event and vim.v.event.status == 0 then
        if vim.api.nvim_buf_is_valid(term_buf) then
          vim.api.nvim_buf_delete(term_buf, { force = true })
        end
      end
      local status = require("neojj.ui.status")
      if status.is_open() then status.refresh() end
    end,
  })
end

function M.new_change(on_done)
  jj.run({ "new" }, {}, with_refresh(on_done))
end

function M.describe(message, rev, on_done)
  local args = { "describe", "-m", message }
  if rev then table.insert(args, rev) end
  jj.run(args, {}, with_refresh(on_done))
end

function M.squash(on_done)
  jj.run({ "squash" }, {}, with_refresh(on_done))
end

function M.squash_rev(rev, on_done)
  jj.run({ "squash", "-r", rev }, {}, with_refresh(on_done))
end

function M.edit(rev, on_done)
  jj.run({ "edit", rev }, {}, with_refresh(on_done))
end

function M.abandon(rev, on_done)
  jj.run({ "abandon", rev }, {}, with_refresh(on_done))
end

function M.undo(on_done)
  jj.run({ "undo" }, {}, with_refresh(on_done))
end

function M.split()
  M.open_in_terminal({ "split" })
end

function M.duplicate(rev, on_done)
  local args = { "duplicate" }
  if rev then table.insert(args, rev) end
  jj.run(args, {}, with_refresh(on_done))
end

function M.rebase_dest(dest, on_done)
  jj.run({ "rebase", "-d", dest }, {}, with_refresh(on_done))
end

function M.rebase_source(source, dest, on_done)
  jj.run({ "rebase", "-s", source, "-d", dest }, {}, with_refresh(on_done))
end

function M.rebase_branch(branch, dest, on_done)
  jj.run({ "rebase", "-b", branch, "-d", dest }, {}, with_refresh(on_done))
end

function M.bookmark_set(name, rev, on_done)
  local args = { "bookmark", "set", name }
  if rev then vim.list_extend(args, { "-r", rev }) end
  jj.run(args, {}, with_refresh(on_done))
end

function M.bookmark_create(name, rev, on_done)
  local args = { "bookmark", "create", name }
  if rev then vim.list_extend(args, { "-r", rev }) end
  jj.run(args, {}, with_refresh(on_done))
end

function M.bookmark_delete(name, on_done)
  jj.run({ "bookmark", "delete", name }, {}, with_refresh(on_done))
end

function M.bookmark_track(name, remote, on_done)
  remote = remote or config.values.default_remote
  jj.run({ "bookmark", "track", name .. "@" .. remote }, {}, with_refresh(on_done))
end

function M.bookmark_advance(name, on_done)
  jj.run({ "bookmark", "advance", name }, {}, with_refresh(on_done))
end

function M.bookmark_move(name, dest, on_done)
  jj.run({ "bookmark", "move", name, "--to", dest }, {}, with_refresh(on_done))
end

function M.git_fetch(remote, on_done)
  local args = { "git", "fetch" }
  if remote then vim.list_extend(args, { "--remote", remote }) end
  jj.run(args, {}, with_refresh(on_done))
end

function M.git_push(bookmark, on_done)
  local args = { "git", "push" }
  if bookmark then vim.list_extend(args, { "--bookmark", bookmark }) end
  jj.run(args, {}, with_refresh(on_done))
end

function M.git_push_all(on_done)
  jj.run({ "git", "push", "--all" }, {}, with_refresh(on_done))
end

function M.git_export(on_done)
  jj.run({ "git", "export" }, {}, with_refresh(on_done))
end

function M.git_import(on_done)
  jj.run({ "git", "import" }, {}, with_refresh(on_done))
end

function M.git_remote_list(on_done)
  jj.run({ "git", "remote", "list" }, {}, function(result)
    if on_done then on_done(result) end
  end)
end

function M.git_remote_add(name, url, on_done)
  jj.run({ "git", "remote", "add", name, url }, {}, with_refresh(on_done))
end

function M.git_remote_remove(name, on_done)
  jj.run({ "git", "remote", "remove", name }, {}, with_refresh(on_done))
end

function M.op_restore(op_id, on_done)
  jj.run({ "operation", "restore", op_id }, {}, with_refresh(on_done))
end

return M
