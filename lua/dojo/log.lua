--- Simple debug logger for dojo.nvim.
--- Writes to a file so users can attach logs to issue reports.
local M = {}

local log_path = vim.fn.stdpath("state") .. "/dojo.log"

local function is_enabled()
  return require("dojo.config").values.debug
end

---@param level string "DEBUG"|"INFO"|"WARN"|"ERROR"
---@param msg string
local function write(level, msg)
  if not is_enabled() then return end
  local f = io.open(log_path, "a")
  if not f then return end
  local timestamp = os.date("%Y-%m-%d %H:%M:%S")
  f:write(string.format("[%s] %s: %s\n", timestamp, level, msg))
  f:close()
end

function M.debug(msg) write("DEBUG", msg) end
function M.info(msg) write("INFO", msg) end
function M.warn(msg) write("WARN", msg) end
function M.error(msg) write("ERROR", msg) end

--- Log a jj command and its result.
---@param args string[] command args
---@param result table { code, stdout, stderr }
function M.command(args, result)
  local cmd_str = table.concat(args, " ")
  if result.code == 0 then
    write("DEBUG", "jj " .. cmd_str .. " -> ok")
  else
    write("ERROR", "jj " .. cmd_str .. " -> exit " .. result.code)
    if result.stderr and result.stderr ~= "" then
      write("ERROR", "  stderr: " .. vim.trim(result.stderr))
    end
  end
end

--- Get the log file path.
---@return string
function M.path()
  return log_path
end

--- Open the log file in a split.
function M.open()
  vim.cmd("botright split " .. vim.fn.fnameescape(log_path))
end

--- Clear the log file.
function M.clear()
  local f = io.open(log_path, "w")
  if f then f:close() end
  vim.notify("Cleared " .. log_path, vim.log.levels.INFO)
end

return M
