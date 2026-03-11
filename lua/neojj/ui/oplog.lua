--- Operation log buffer.
local M = {}

local jj = require("neojj.jj")
local parser = require("neojj.jj.parser")
local ui = require("neojj.ui")
local render = require("neojj.ui.render")

local BUF_NAME = "neojj://oplog"
local line_meta = {}

--- Open the operation log view.
function M.open()
  jj.run({ "operation", "log" }, {}, function(result)
    if result.code ~= 0 then
      vim.notify("jj op log: " .. vim.trim(result.stderr), vim.log.levels.ERROR)
      return
    end
    M._display(result.stdout)
  end)
end

--- Display operation log.
function M._display(stdout)
  local buf = ui.get_or_create(BUF_NAME)
  ui.open(buf)

  local parsed = parser.parse_oplog(stdout)
  local lines = {}
  line_meta = {}

  for _, entry in ipairs(parsed) do
    local hls = {}
    if entry.marker == "@" then
      table.insert(hls, { "NeoJJCurrent", 0, #entry.text })
    end
    table.insert(lines, {
      text = entry.text,
      highlights = hls,
      meta = entry.op_id and { type = "operation", op_id = entry.op_id } or nil,
    })
  end

  render.render(buf, lines, line_meta)

  local map = render.map

  local function go_back()
    ui.close(BUF_NAME)
    line_meta = {}
    require("neojj.ui.status").open()
  end

  map(buf, "<BS>", go_back)
  map(buf, "q", go_back)
  map(buf, "j", function() render.move_to_meta(line_meta, 1) end)
  map(buf, "k", function() render.move_to_meta(line_meta, -1) end)
  map(buf, "R", function()
    local meta = render.get_cursor_meta(line_meta)
    if meta and meta.op_id then
      vim.ui.select({ "Yes", "No" }, { prompt = "Restore to operation " .. meta.op_id .. "?" }, function(choice)
        if choice == "Yes" then
          require("neojj.jj.commands").op_restore(meta.op_id)
        end
      end)
    end
  end)
end

return M
