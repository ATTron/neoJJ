--- Git popup (fetch, push, export, import, remotes).
local M = {}

local popup = require("neojj.popup")
local commands = require("neojj.jj.commands")

function M.open()
  popup.open({
    title = "Git",
    items = {
      { "f", "fetch (all remotes)", function() commands.git_fetch() end },
      { "F", "fetch from remote...", function()
        vim.ui.input({ prompt = "Remote: " }, function(remote)
          if remote then commands.git_fetch(remote) end
        end)
      end },
      { "p", "push", function() commands.git_push(nil) end },
      { "b", "push bookmark...", function()
        vim.ui.input({ prompt = "Bookmark to push: " }, function(name)
          if name then commands.git_push(name) end
        end)
      end },
      { "P", "push all bookmarks", function() commands.git_push_all() end },
      { "e", "export to git", function() commands.git_export() end },
      { "i", "import from git", function() commands.git_import() end },
      { "l", "list remotes", function()
        commands.git_remote_list(function(result)
          if result.code ~= 0 then
            vim.notify("jj git remote list: " .. vim.trim(result.stderr), vim.log.levels.ERROR)
            return
          end
          local output = vim.trim(result.stdout)
          if output == "" then
            vim.notify("No remotes configured", vim.log.levels.INFO)
          else
            vim.notify(output, vim.log.levels.INFO)
          end
        end)
      end },
      { "a", "add remote", function()
        vim.ui.input({ prompt = "Remote name: " }, function(name)
          if not name then return end
          vim.ui.input({ prompt = "URL: " }, function(url)
            if url then commands.git_remote_add(name, url) end
          end)
        end)
      end },
      { "r", "remove remote", function()
        vim.ui.input({ prompt = "Remote to remove: " }, function(name)
          if name then commands.git_remote_remove(name) end
        end)
      end },
    },
  })
end

return M
