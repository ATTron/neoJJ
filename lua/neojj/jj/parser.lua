local M = {}

local SEP = "\t"

--- Parse jj status output
---@param stdout string raw output from jj status
---@return {files: table[], parent_description: string}
function M.parse_status(stdout)
  local result = { files = {} }
  for line in stdout:gmatch("[^\n]+") do
    -- jj status lines look like: M src/main.rs
    -- or: A src/new_file.rs
    -- Working copy changes heading
    if line:match("^Working copy")
      or line:match("^Parent commit")
      or line:match("^The working copy")
      or line:match("^Added ")
      or line:match("^$") then
      -- skip jj status header/info lines
    else
      -- File status lines have a 1-2 char status code: M, A, D, R, C, etc.
      local status, path = line:match("^(%a%a?)%s+(.+)$")
      if status and path then
        table.insert(result.files, { status = status, path = path })
      end
    end
  end
  return result
end

--- Parse jj log output using template with tab separators
--- Template: change_id.short() ++ "\t" ++ commit_id.short() ++ "\t" ++ description.first_line() ++ "\t" ++ bookmarks ++ "\t" ++ author.timestamp().ago() ++ "\t" ++ if(conflict, "conflict") ++ "\t" ++ if(empty, "empty") ++ "\t" ++ working_copies
---@param stdout string raw output from jj log --no-graph -T template
---@return table[] entries
function M.parse_log(stdout)
  local entries = {}
  for record in stdout:gmatch("[^\n]+") do
    local parts = {}
    for part in (record .. SEP):gmatch("(.-)" .. SEP) do
      table.insert(parts, part)
    end
    if #parts >= 5 then
      table.insert(entries, {
        change_id = parts[1],
        commit_id = parts[2],
        description = parts[3] ~= "" and parts[3] or "(no description set)",
        bookmarks = parts[4] ~= "" and parts[4] or nil,
        timestamp = parts[5],
        conflict = parts[6] == "conflict",
        empty = parts[7] == "empty",
        is_working_copy = parts[8] ~= nil and parts[8] ~= "",
      })
    end
  end
  return entries
end

--- Parse jj log with graph (raw lines, for full log view)
---@param stdout string raw output from jj log (with graph)
---@return table[] lines with {text, change_id?}
function M.parse_log_graph(stdout)
  local lines = {}
  for line in stdout:gmatch("[^\n]*") do
    local entry = { text = line }
    -- Try to extract change_id from graph lines like: @  ksqpmoyl ...
    -- or: o  ztqrpmov ...
    local marker, rest = line:match("^([@ |o*x%.%-]+)%s+(%S.*)")
    if marker and rest then
      local change_id = rest:match("^(%S+)")
      if change_id and #change_id >= 4 then
        entry.change_id = change_id
        entry.marker = vim.trim(marker)
      end
    end
    table.insert(lines, entry)
  end
  return lines
end

--- Parse jj bookmark list output (remote lines filtered out by template)
--- Output per line: name \t tracked|local \t commit_id
---@param stdout string raw output from jj bookmark list -T template
---@return table[] bookmarks
function M.parse_bookmarks(stdout)
  local bookmarks = {}
  for line in stdout:gmatch("[^\n]+") do
    local parts = {}
    for part in (line .. SEP):gmatch("(.-)" .. SEP) do
      table.insert(parts, part)
    end
    if #parts >= 3 then
      table.insert(bookmarks, {
        name = parts[1],
        tracking = parts[2] == "tracked",
        commit_id = parts[3],
      })
    end
  end
  return bookmarks
end

--- Parse jj op log output
---@param stdout string raw output from jj op log
---@return table[] operations
function M.parse_oplog(stdout)
  local ops = {}
  for line in stdout:gmatch("[^\n]*") do
    local entry = { text = line }
    -- Operation IDs appear at the start of graph lines
    local marker, rest = line:match("^([@ |o%.%-]+)%s+(%S.*)")
    if marker and rest then
      local op_id = rest:match("^(%S+)")
      if op_id then
        entry.op_id = op_id
        entry.marker = vim.trim(marker)
      end
    end
    table.insert(ops, entry)
  end
  return ops
end

--- Build the template string for jj log
---@return string
function M.log_template()
  return table.concat({
    'change_id.short()',
    '"\t"',
    'commit_id.short()',
    '"\t"',
    'description.first_line()',
    '"\t"',
    'bookmarks',
    '"\t"',
    'author.timestamp().ago()',
    '"\t"',
    'if(conflict, "conflict")',
    '"\t"',
    'if(empty, "empty")',
    '"\t"',
    'if(current_working_copy, "@")',
    '"\n"',
  }, " ++ ")
end

--- Build the template string for jj bookmark list
---@return string
function M.bookmark_template()
  -- Skip remote entries (output nothing), only emit local bookmarks
  return 'if(remote, "", name ++ "\t" ++ if(tracking_present, "tracked", "local") ++ "\t" ++ if(normal_target, normal_target.commit_id().short(), "???") ++ "\n")'
end

return M
