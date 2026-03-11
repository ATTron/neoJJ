--- Dynamic alias popup — auto-discovered from jj config.
local M = {}

local popup = require("neojj.popup")
local aliases_mod = require("neojj.jj.aliases")
local jj = require("neojj.jj")
local commands = require("neojj.jj.commands")

--- Assign keys to aliases, avoiding conflicts.
---@param aliases table[]
---@return table[] items {key, label, action}
local function assign_keys(aliases)
  local used = { q = true, ["<Esc>"] = true } -- reserved
  local items = {}

  for _, a in ipairs(aliases) do
    local key = nil

    -- Try: single-letter alias name if available
    if #a.name == 1 and not used[a.name] then
      key = a.name
    end

    -- Try: first unused letter from the alias name
    if not key then
      for i = 1, #a.name do
        local ch = a.name:sub(i, i):lower()
        if ch:match("%a") and not used[ch] then
          key = ch
          break
        end
      end
    end

    -- Fallback: numbered keys
    if not key then
      for n = 1, 9 do
        local k = tostring(n)
        if not used[k] then
          key = k
          break
        end
      end
    end

    if key then
      used[key] = true
      local label = a.name .. "  →  " .. a.description

      local is_exec = a.command[1] == "util" and a.command[2] == "exec"

      table.insert(items, { key, label, function()
        if is_exec then
          commands.open_in_terminal(a.command)
        else
          vim.notify("jj " .. a.name .. " ...", vim.log.levels.INFO)
          jj.run(a.command, {}, function(result)
            if result.code ~= 0 then
              vim.notify("jj " .. a.name .. ": " .. vim.trim(result.stderr), vim.log.levels.ERROR)
            else
              vim.notify("jj " .. a.name .. " done", vim.log.levels.INFO)
            end
            local status = require("neojj.ui.status")
            if status.is_open() then status.refresh() end
          end)
        end
      end })
    end
  end

  return items
end

function M.open()
  aliases_mod.get(function(aliases)
    if #aliases == 0 then
      vim.notify("No jj aliases found", vim.log.levels.INFO)
      return
    end

    popup.open({
      title = "Aliases (from jj config)",
      items = assign_keys(aliases),
    })
  end)
end

return M
