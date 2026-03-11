--- Full log buffer with graph.
local M = {}

local jj = require("neojj.jj")
local parser = require("neojj.jj.parser")
local ui = require("neojj.ui")
local render = require("neojj.ui.render")

local BUF_NAME = "neojj://log"
local line_meta = {}

--- Open the full log view.
function M.open()
  jj.run({ "log" }, {}, function(result)
    if result.code ~= 0 then
      vim.notify("jj log: " .. vim.trim(result.stderr), vim.log.levels.ERROR)
      return
    end
    M._display(result.stdout)
  end)
end

--- Display log output with graph.
function M._display(stdout)
  local buf = ui.get_or_create(BUF_NAME)
  ui.open(buf)

  local parsed = parser.parse_log_graph(stdout)
  local lines = {}
  line_meta = {}

  for _, entry in ipairs(parsed) do
    local hls = {}
    if entry.marker == "@" then
      table.insert(hls, { "NeoJJCurrent", 0, #entry.text })
    elseif entry.change_id then
      local start = entry.text:find(entry.change_id, 1, true)
      if start then
        table.insert(hls, { "NeoJJChangeId", start - 1, start - 1 + #entry.change_id })
      end
    end

    table.insert(lines, {
      text = entry.text,
      highlights = hls,
      meta = entry.change_id and { type = "log_entry", change_id = entry.change_id } or nil,
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
  map(buf, "<CR>", function()
    local meta = render.get_cursor_meta(line_meta)
    if meta and meta.change_id then
      require("neojj.ui.diff").show(meta.change_id)
    end
  end)
  map(buf, "e", function()
    local meta = render.get_cursor_meta(line_meta)
    if meta and meta.change_id then
      require("neojj.jj.commands").edit(meta.change_id)
    end
  end)
end

return M
