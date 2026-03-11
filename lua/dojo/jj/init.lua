local M = {}

local config = require("dojo.config")

---@type string|nil
M._workspace_root = nil

--- Get the jj workspace root (cached)
---@param callback fun(root: string|nil)
function M.root(callback)
  if M._workspace_root then
    callback(M._workspace_root)
    return
  end
  M.run({ "root" }, {}, function(result)
    if result.code == 0 then
      M._workspace_root = vim.trim(result.stdout)
      callback(M._workspace_root)
    else
      callback(nil)
    end
  end)
end

--- Run a jj command asynchronously
---@param args string[] command arguments
---@param opts table? options: cwd, on_stdout
---@param callback fun(result: {code: integer, stdout: string, stderr: string})
function M.run(args, opts, callback)
  opts = opts or {}
  local cmd = vim.list_extend({ config.values.jj_binary, "--no-pager", "--color=never" }, args)

  local cwd = opts.cwd or M._workspace_root or vim.fn.getcwd()

  vim.system(cmd, {
    cwd = cwd,
    text = true,
  }, function(obj)
    vim.schedule(function()
      local result = {
        code = obj.code,
        stdout = obj.stdout or "",
        stderr = obj.stderr or "",
      }
      require("dojo.log").command(args, result)
      callback(result)
    end)
  end)
end

return M
