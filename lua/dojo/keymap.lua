--- Keymap registration for the status buffer.
local M = {}

local status = require("dojo.ui.status")
local commands = require("dojo.jj.commands")
local map = require("dojo.ui.render").map

--- Attach all status buffer keybindings.
---@param buf integer
function M.attach(buf)
  -- Navigation
  map(buf, "j", function() status.move_item(1) end)
  map(buf, "k", function() status.move_item(-1) end)
  map(buf, "J", function() status.move_section(1) end)
  map(buf, "K", function() status.move_section(-1) end)

  -- Core actions
  map(buf, "q", function() status.close() end)
  map(buf, "gr", function() status.refresh() end)
  map(buf, "<Tab>", function() status.toggle_fold() end)

  map(buf, "<CR>", function()
    local meta = status.cursor_meta()
    if not meta then return end
    if meta.type == "file" then
      require("dojo.ui.diff").show_file(meta.path)
    elseif meta.change_id then
      require("dojo.ui.diff").show(meta.change_id)
    end
  end)

  -- Direct commands
  map(buf, "n", function() commands.new_change() end)
  map(buf, "D", function()
    local meta = status.cursor_meta()
    local rev = meta and meta.change_id or nil
    require("dojo.ui.describe").open(rev)
  end)
  map(buf, "s", function() commands.squash() end)
  map(buf, "e", function()
    local meta = status.cursor_meta()
    if meta and meta.change_id then
      commands.edit(meta.change_id)
    else
      vim.ui.input({ prompt = "Edit revision: " }, function(rev)
        if rev then commands.edit(rev) end
      end)
    end
  end)
  map(buf, "a", function()
    local meta = status.cursor_meta()
    local target = (meta and meta.change_id) or "@"
    vim.ui.select({ "Yes", "No" }, { prompt = "Abandon " .. target .. "?" }, function(choice)
      if choice == "Yes" then commands.abandon(target) end
    end)
  end)
  map(buf, "u", function() commands.undo() end)

  -- Diff for change under cursor
  map(buf, "d", function()
    local meta = status.cursor_meta()
    if meta and meta.change_id then
      require("dojo.ui.diff").show(meta.change_id)
    elseif meta and meta.path then
      require("dojo.ui.diff").show_file(meta.path)
    end
  end)

  -- Full working copy diff
  map(buf, "S", function() require("dojo.ui.diff").show() end)

  -- Full log view
  map(buf, "l", function() require("dojo.ui.log").open() end)

  -- Popups
  map(buf, "c", function() require("dojo.popup.change").open() end)
  map(buf, "b", function() require("dojo.popup.bookmark").open() end)
  map(buf, "R", function() require("dojo.popup.rebase").open() end)
  map(buf, "f", function() require("dojo.popup.remote").open() end)
  map(buf, "o", function() require("dojo.popup.operation").open() end)
  map(buf, "x", function() require("dojo.popup.aliases").open() end)

  -- Help
  map(buf, "?", function() M._show_help() end)
end

--- Show a help popup with all keybindings.
function M._show_help()
  require("dojo.popup").open({
    title = "Dojo Help",
    width = 50,
    items = {
      { "q", "close", function() end },
      { "gr", "refresh", function() end },
      { "<CR>", "open diff / show", function() end },
      { "<Tab>", "toggle fold", function() end },
      { "n", "new change", function() end },
      { "D", "describe", function() end },
      { "s", "squash", function() end },
      { "e", "edit change", function() end },
      { "a", "abandon", function() end },
      { "u", "undo", function() end },
      { "d", "diff", function() end },
      { "S", "full working copy diff", function() end },
      { "l", "log view", function() end },
      { "c", "change popup", function() end },
      { "b", "bookmark popup", function() end },
      { "R", "rebase popup", function() end },
      { "f", "git popup", function() end },
      { "o", "operation popup", function() end },
      { "x", "aliases popup", function() end },
      { "j/k", "move items", function() end },
      { "J/K", "move sections", function() end },
    },
  })
end

return M
