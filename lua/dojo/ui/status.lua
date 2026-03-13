--- Main status buffer — the heart of dojo.nvim.
--- Combines jj status + jj log + bookmarks into one view.
local M = {}

local config = require("dojo.config")
local jj = require("dojo.jj")
local parser = require("dojo.jj.parser")
local ui = require("dojo.ui")
local render = require("dojo.ui.render")

local BUF_NAME = "dojo://status"

-- Optional: nvim-web-devicons for file icons
local has_devicons, devicons = pcall(require, "nvim-web-devicons")

-- Nerd font icons (used when config.values.icons is true)
local nerd_icons = {
  working_copy = "\u{f044}  ",  --  section
  conflicts    = "\u{f071}  ",  --  section
  log          = "\u{f1da}  ",  --  section
  bookmarks    = "\u{f02e} ",   --  section (already spaced well)
  aliases      = "\u{f120}  ",  --  section
  diff_stat    = "\u{f1fc}  ",  --  section
  change       = "",
  description  = "",
  clean        = "",
  modified     = "\u{f040}  ",  --  file status
  added        = "\u{f067}  ",  --  file status
  deleted      = "\u{f068}  ",  --  file status
  renamed      = "\u{f064}  ",  --  file status
}

-- Plain text fallback
local plain_icons = {
  working_copy = "", conflicts = "", log = "",
  bookmarks = "", aliases = "", diff_stat = "", change = "", description = "",
  clean = "", modified = "[M] ", added = "[A] ",
  deleted = "[D] ", renamed = "[R] ",
}

-- Per-buffer metadata: line_meta[line_nr] = { type, change_id, path, ... }
local line_meta = {}

-- Fold state: collapsed sections
local folds = {}

-- Debounce: track the current refresh generation to discard stale results
local refresh_gen = 0

-- Cache last query results so fold toggles can re-render without re-querying
local last_results = nil
local last_results_time = 0
local RESULT_CACHE_MS = 200

-- File watcher for auto-refresh
local watcher = nil
local refresh_timer = nil

-- Lazy alias fetch: only once per session
local aliases_fetched = false

--- Is the status buffer open?
function M.is_open()
  return ui.get_buf(BUF_NAME) ~= nil
end

--- Get the status buffer number (or nil).
function M.get_buf()
  return ui.get_buf(BUF_NAME)
end

--- Open the status buffer.
function M.open()
  jj.root(function(root)
    if not root then
      local cwd = vim.fn.getcwd()
      local has_git = vim.fn.isdirectory(cwd .. "/.git") == 1

      local prompt
      if has_git then
        prompt = "Not a jj workspace. Run `jj git init --colocate` here?"
      else
        prompt = "Not a jj workspace. Run `jj git init` here?"
      end

      vim.ui.select({ "Yes", "No" }, { prompt = prompt }, function(choice)
        if choice ~= "Yes" then return end
        local cmd = has_git
          and { "git", "init", "--colocate" }
          or { "git", "init" }
        jj.run(cmd, { cwd = cwd }, function(result)
          if result.code ~= 0 then
            vim.notify("jj: " .. vim.trim(result.stderr), vim.log.levels.ERROR)
            return
          end
          vim.notify("Initialized jj workspace", vim.log.levels.INFO)
          -- Clear cached root and open
          jj._workspace_root = nil
          M.open()
        end)
      end)
      return
    end

    local buf = ui.get_or_create(BUF_NAME)
    local mode = config.values.open_mode
    local split = nil
    if mode == "split" then split = "h"
    elseif mode == "vsplit" then split = "v"
    end
    ui.open(buf, split)
    M.refresh()
    require("dojo.keymap").attach(buf)
    M._start_watcher(root)
  end)
end

--- Close the status buffer.
function M.close()
  M._stop_watcher()
  require("dojo.popup").close_all()
  ui.close(BUF_NAME)
  line_meta = {}
end

--- Invalidate the result cache so the next refresh queries fresh data.
function M.invalidate()
  last_results_time = 0
end

--- Refresh: query jj and re-render.
--- Debounced — rapid calls discard stale results.
function M.refresh()
  local buf = ui.get_buf(BUF_NAME)
  if not buf then return end

  -- Fetch aliases lazily on first refresh
  if not aliases_fetched then
    aliases_fetched = true
    require("dojo.jj.aliases").fetch(function() end)
  end

  -- If we have recent results, just re-render from cache
  local now = vim.uv.hrtime() / 1e6
  if last_results and (now - last_results_time) < RESULT_CACHE_MS then
    local cursor_ok, cursor = pcall(vim.api.nvim_win_get_cursor, 0)
    local saved_row = cursor_ok and cursor[1] or 1
    M._render(buf, last_results, saved_row)
    return
  end

  -- Bump generation so any in-flight refresh is discarded
  refresh_gen = refresh_gen + 1
  local my_gen = refresh_gen

  -- Save cursor position
  local cursor_ok, cursor = pcall(vim.api.nvim_win_get_cursor, 0)
  local saved_row = cursor_ok and cursor[1] or 1

  -- Query jj status, log, bookmarks, and diff stat in parallel
  local results = {}
  local pending = 4

  local function on_complete()
    pending = pending - 1
    if pending > 0 then return end
    if my_gen ~= refresh_gen then return end
    M._render(buf, results, saved_row)
  end

  jj.run({ "status" }, {}, function(r)
    results.status = r
    on_complete()
  end)

  jj.run({
    "log", "--no-graph", "-T", parser.log_template(),
    "--limit", tostring(config.values.log_limit),
  }, {}, function(r)
    results.log = r
    on_complete()
  end)

  jj.run({
    "bookmark", "list", "-T", parser.bookmark_template(),
  }, {}, function(r)
    results.bookmarks = r
    on_complete()
  end)

  jj.run({ "diff", "--stat" }, {}, function(r)
    results.diff_stat = r
    on_complete()
  end)
end

--- Build and render the status buffer content.
---@param buf integer
---@param results table raw query results
---@param saved_row integer cursor row to restore
function M._render(buf, results, saved_row)
  if not vim.api.nvim_buf_is_valid(buf) then return end
  last_results = results
  last_results_time = vim.uv.hrtime() / 1e6

  local icons = config.values.icons and nerd_icons or plain_icons
  local use_devicons = config.values.icons and has_devicons

  local status = parser.parse_status(results.status.stdout or "")
  local log_entries = parser.parse_log(results.log.stdout or "")
  local bookmarks = parser.parse_bookmarks(results.bookmarks.stdout or "")

  local lines = {}
  line_meta = {}

  -- Find working copy entry (nil-safe)
  local wc = nil
  for _, entry in ipairs(log_entries) do
    if entry.is_working_copy then
      wc = entry
      break
    end
  end
  if not wc and #log_entries > 0 then
    wc = log_entries[1]
  end

  -- Find parent entry (nil-safe)
  local parent = nil
  if wc and #log_entries >= 2 then
    for i, entry in ipairs(log_entries) do
      if entry == wc and log_entries[i + 1] then
        parent = log_entries[i + 1]
        break
      end
    end
  end
  if not parent and #log_entries >= 2 then
    parent = log_entries[2]
  end

  local function add(line) table.insert(lines, line) end
  local function add_section(title, fold_key, hint)
    fold_key = fold_key or title
    local arrow = folds[fold_key] and "▸" or "▾"
    local text = arrow .. " " .. title
    local hls = { { "DojoSectionHeader", 0, #text } }
    if hint then
      local hint_start = #text
      text = text .. "  " .. hint
      table.insert(hls, { "DojoDim", hint_start, #text })
    end
    add({
      text = text,
      highlights = hls,
      meta = { type = "section", name = fold_key },
    })
  end

  -- Render change ID + description lines for an entry
  local function add_entry(entry, meta_extras)
    local prefix = icons.change
    local hls = {}

    -- "Change: abc123  Commit: def456  bookmarks"
    local text = prefix .. "Change: " .. entry.change_id .. "  Commit: " .. entry.commit_id
    local p = #prefix
    table.insert(hls, { "DojoChangeId", p + 8, p + 8 + #entry.change_id })
    table.insert(hls, { "DojoCommitId", p + 8 + #entry.change_id + 10, #text })

    -- Append bookmarks inline on the same line
    if entry.bookmarks then
      text = text .. "  " .. icons.bookmarks .. entry.bookmarks
      local bm_start = #text - #entry.bookmarks
      table.insert(hls, { "DojoBookmark", bm_start, #text })
    end

    add({
      text = text,
      highlights = hls,
      meta = vim.tbl_extend("force", { type = "change", change_id = entry.change_id }, meta_extras or {}),
    })

    local no_desc = entry.description == "(no description set)"
    local desc_prefix = icons.description
    local desc_text = desc_prefix .. "Description: " .. entry.description
    local dp = #desc_prefix
    add({
      text = desc_text,
      highlights = no_desc
        and { { "DojoDim", 0, #desc_text } }
        or { { "DojoDescription", dp + 13, dp + 13 + #entry.description } },
    })
  end

  add_section(icons.working_copy .. "Working Copy (@)", "Working Copy (@)")

  if wc then
    add_entry(wc)
  else
    add({
      text = "  (no data)",
      highlights = { { "DojoDim", 0, 11 } },
    })
  end

  -- Working copy files
  if not folds["Working Copy (@)"] then
    for _, f in ipairs(status.files) do
      local badge_info = ({
        M = { icons.modified, "DojoFileModified" },
        A = { icons.added, "DojoFileAdded" },
        D = { icons.deleted, "DojoFileDeleted" },
        R = { icons.renamed, "DojoFileRenamed" },
      })[f.status] or { icons.modified, "DojoFileModified" }
      local status_icon, badge_hl = badge_info[1], badge_info[2]

      -- Get file icon from devicons if available
      local file_icon, icon_hl = "", nil
      if use_devicons then
        local ext = f.path:match("%.(%w+)$")
        file_icon, icon_hl = devicons.get_icon(f.path, ext, { default = true })
        file_icon = (file_icon or "") .. " "
      end

      local text = "  " .. status_icon .. file_icon .. f.path
      local si_end = 2 + #status_icon
      local fi_end = si_end + #file_icon
      local hls = {
        { badge_hl, 2, si_end },
        { "DojoFilePath", fi_end, fi_end + #f.path },
      }
      if icon_hl then
        table.insert(hls, { icon_hl, si_end, fi_end })
      end
      add({
        text = text,
        highlights = hls,
        meta = { type = "file", path = f.path, status = f.status },
      })
    end
    if #status.files == 0 then
      add({
        text = "  " .. icons.clean .. "(clean)",
        highlights = { { "DojoDim", 0, -1 } },
      })
    end
  end

  add("")

  -- === Diff Stat === (collapsed by default)
  local diff_stat_lines = vim.split(vim.trim(results.diff_stat.stdout or ""), "\n")
  if #diff_stat_lines > 0 and diff_stat_lines[1] ~= "" then
    -- Start collapsed on first render
    if folds["Diff Stat"] == nil then folds["Diff Stat"] = true end

    add_section(icons.diff_stat .. "Diff Stat", "Diff Stat")
    if not folds["Diff Stat"] then
      for _, line in ipairs(diff_stat_lines) do
        local text = "  " .. line
        local hls = {}
        local meta = nil
        local bar_start = text:find("|")
        if bar_start then
          -- Extract file path (everything before the |, trimmed)
          local path = vim.trim(line:match("^(.-)%s*|"))
          if path and path ~= "" then
            -- jj diff --stat truncates long paths with "..." prefix.
            -- Resolve truncated paths against full paths from jj status.
            if path:match("^%.%.%.") then
              local suffix = path:sub(4) -- strip leading "..."
              for _, f in ipairs(status.files) do
                if f.path:find(suffix, 1, true) then
                  path = f.path
                  break
                end
              end
              -- If still truncated (no match found), skip it
              if path:match("^%.%.%.") then path = nil end
            end
            if path then
              meta = { type = "file", path = path }
            end
          end
          local plus_start = text:find("%+", bar_start)
          local minus_start = text:find("%-", bar_start)
          if plus_start then
            table.insert(hls, { "DojoFileAdded", plus_start - 1, #text })
          end
          if minus_start then
            table.insert(hls, { "DojoFileDeleted", minus_start - 1, #text })
          end
        else
          table.insert(hls, { "DojoDim", 0, #text })
        end
        add({ text = text, highlights = hls, meta = meta })
      end
    end
    add("")
  end

  -- === Conflicts === (only if any entries have conflicts)
  local has_conflicts = false
  for _, entry in ipairs(log_entries) do
    if entry.conflict then
      has_conflicts = true
      break
    end
  end
  if has_conflicts then
    add_section(icons.conflicts .. "Conflicts", "Conflicts")
    if not folds["Conflicts"] then
      for _, entry in ipairs(log_entries) do
        if entry.conflict then
          add({
            text = "  " .. entry.change_id .. " (conflict)",
            highlights = { { "DojoConflict", 2, #entry.change_id + 2 } },
            meta = { type = "change", change_id = entry.change_id },
          })
        end
      end
    end
    add("")
  end

  -- === Recent Log ===
  if #log_entries > 0 then
    add_section(icons.log .. "Recent Log", "Recent Log")
    if not folds["Recent Log"] then
      for _, entry in ipairs(log_entries) do
        -- Skip working copy — already shown above
        if entry.is_working_copy then goto continue end

        local is_parent = parent and entry.change_id == parent.change_id
        local hls = {}
        local col = 0
        local text = "  "
        col = #text

        -- Change ID
        local id_start = col
        text = text .. entry.change_id
        col = #text
        table.insert(hls, { "DojoChangeId", id_start, col })

        -- Parent label
        if is_parent then
          text = text .. " (parent)"
          table.insert(hls, { "DojoParent", col, col + 9 })
          col = #text
        end

        -- Description (truncate if long)
        text = text .. "  "
        col = #text
        local desc = entry.description
        if #desc > 40 then desc = desc:sub(1, 37) .. "..." end
        local desc_start = col
        text = text .. desc
        col = #text
        if entry.description == "(no description set)" then
          table.insert(hls, { "DojoDim", desc_start, col })
        end

        -- Empty tag
        if entry.empty then
          text = text .. " (empty)"
          table.insert(hls, { "DojoEmpty", col, col + 8 })
          col = #text
        end

        -- Bookmarks
        if entry.bookmarks then
          text = text .. "  "
          col = #text
          local bm_start = col
          text = text .. entry.bookmarks
          col = #text
          table.insert(hls, { "DojoBookmark", bm_start, col })
        end

        -- Timestamp
        text = text .. "  "
        col = #text
        local ts_start = col
        text = text .. entry.timestamp
        table.insert(hls, { "DojoTimestamp", ts_start, #text })

        add({
          text = text,
          highlights = hls,
          meta = { type = "log_entry", change_id = entry.change_id },
        })
        ::continue::
      end
    end
    add("")
  end

  -- === Bookmarks ===
  if #bookmarks > 0 then
    add_section(icons.bookmarks .. "Bookmarks", "Bookmarks")
    if not folds["Bookmarks"] then
      for _, bm in ipairs(bookmarks) do
        local suffix = bm.tracking and "  (tracked)" or ""
        local text = "  " .. bm.name .. " -> " .. (bm.commit_id or "???") .. suffix
        local hls = { { "DojoBookmark", 2, 2 + #bm.name } }
        if bm.tracking then
          table.insert(hls, { "DojoBookmarkRemote", #text - #suffix, #text })
        end
        add({
          text = text,
          highlights = hls,
          meta = { type = "bookmark", name = bm.name, commit_id = bm.commit_id },
        })
      end
    end
    add("")
  end

  -- === Aliases === (if cached)
  local alias_cache = require("dojo.jj.aliases").get_cache()
  if alias_cache and #alias_cache > 0 then
    add_section(icons.aliases .. "Aliases", "Aliases", "press x to open menu")
    if not folds["Aliases"] then
      for _, a in ipairs(alias_cache) do
        local text = "  " .. a.name .. "  →  " .. a.description
        add({
          text = text,
          highlights = {
            { "DojoAlias", 2, 2 + #a.name },
            { "DojoAliasCmd", 2 + #a.name + 5, #text },
          },
          meta = { type = "alias", alias = a },
        })
      end
    end
    add("")
  end

  render.render(buf, lines, line_meta)

  local max_row = vim.api.nvim_buf_line_count(buf)
  local row = math.min(saved_row, max_row)
  pcall(vim.api.nvim_win_set_cursor, 0, { row, 0 })
end

--- Toggle fold for the section under (or containing) the cursor.
function M.toggle_fold()
  local buf = ui.get_buf(BUF_NAME)
  if not buf or not last_results then return end

  local row = vim.api.nvim_win_get_cursor(0)[1]

  -- Find the section: either on the header or walk upward
  local section_name = nil
  for r = row, 1, -1 do
    local m = line_meta[r]
    if m and m.type == "section" then
      section_name = m.name
      break
    end
  end

  if not section_name then return end

  folds[section_name] = not folds[section_name]
  M._render(buf, last_results, row)
end

--- Get metadata for the line under the cursor.
---@return table|nil
function M.cursor_meta()
  return render.get_cursor_meta(line_meta)
end

--- Navigate to next/prev item (skip blank lines).
---@param direction integer 1 for next, -1 for prev
function M.move_item(direction)
  render.move_to_meta(line_meta, direction)
end

--- Navigate to next/prev section header.
---@param direction integer 1 for next, -1 for prev
function M.move_section(direction)
  render.move_to_meta(line_meta, direction, function(meta)
    return meta.type == "section"
  end)
end

--- Debounced refresh — coalesces rapid file changes into a single refresh.
local function debounced_refresh()
  if refresh_timer then
    refresh_timer:stop()
  end
  refresh_timer = vim.uv.new_timer()
  refresh_timer:start(500, 0, function()
    refresh_timer:stop()
    refresh_timer = nil
    vim.schedule(function()
      if M.is_open() then M.refresh() end
    end)
  end)
end

--- Start watching working copy for changes to auto-refresh.
function M._start_watcher(root)
  M._stop_watcher()
  local w = vim.uv.new_fs_event()
  if not w then return end

  w:start(root, { recursive = true }, function(err, filename)
    if err then return end
    if filename then
      -- Ignore internal/noisy directories
      if filename:match("^%.jj/")
        or filename:match("^%.git/")
        or filename:match("^node_modules/")
        or filename:match("^build/")
        or filename:match("^dist/")
        or filename:match("^target/")
        or filename:match("^%.next/")
        or filename:match("^__pycache__/")
      then
        return
      end
    end
    debounced_refresh()
  end)

  watcher = w
end

--- Stop the file watcher.
function M._stop_watcher()
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer = nil
  end
  if watcher then
    watcher:stop()
    watcher = nil
  end
end

return M
