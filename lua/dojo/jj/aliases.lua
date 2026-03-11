--- Discover and parse aliases from jj config.
local M = {}

local jj = require("dojo.jj")

---@type table[]|nil
M._cache = nil

--- Parse `jj config list aliases` output into a structured table.
--- Lines look like: aliases.s=["log", "--limit", "10"]
---@param stdout string
---@return table[] aliases
local function parse_alias_config(stdout)
  local aliases = {}
  for line in stdout:gmatch("[^\n]+") do
    local name, value = line:match("^aliases%.(%S+)%s*=%s*(.*)")
    if name and value then
      -- value is a JSON array like ["log", "--limit", "10"]
      local ok, parts = pcall(vim.json.decode, value)
      if ok and type(parts) == "table" then
        table.insert(aliases, {
          name = name,
          command = parts,
          description = table.concat(parts, " "),
        })
      elseif not ok then
        vim.notify("dojo.nvim: failed to parse alias '" .. name .. "'", vim.log.levels.WARN)
      end
    end
  end
  table.sort(aliases, function(a, b) return a.name < b.name end)
  return aliases
end

--- Fetch aliases from jj config (async).
---@param callback fun(aliases: table[])
function M.fetch(callback)
  jj.run({ "config", "list", "aliases", "--include-overridden" }, {}, function(result)
    if result.code ~= 0 then
      callback({})
      return
    end
    local aliases = parse_alias_config(result.stdout)
    M._cache = aliases
    callback(aliases)
  end)
end

--- Get cached aliases or fetch them.
---@param callback fun(aliases: table[])
function M.get(callback)
  if M._cache then
    callback(M._cache)
  else
    M.fetch(callback)
  end
end

--- Get the cached aliases (or nil if not yet fetched).
---@return table[]|nil
function M.get_cache()
  return M._cache
end


return M
