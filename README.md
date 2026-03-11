# neoJJ

[Magit](https://github.com/magit/magit) and [neogit](https://github.com/NeogitOrg/neogit) inspried interface for [jj (Jujutsu)](https://github.com/jj-vcs/jj) inside Neovim.

![demo](https://github.com/user-attachments/assets/f69175e9-6efa-43fd-9742-747a872db9d2)

## Install

### lazy.nvim

```lua
{
  "ATTron/neoJJ",
  dependencies = {
    "nvim-tree/nvim-web-devicons", -- optional, used for pretty icons
  },
  keys = {
    { "<leader>jj", "<cmd>NeoJJ<cr>", desc = "Open NeoJJ" },
  },
  config = function()
    require("neojj").setup({
      icons = true, -- enable nerd font icons (requires a patched font)
    })
  end,
}
```

### vim.pack (Neovim 0.12+)

Neovim 0.12 ships with a built-in package manager. Add this to your config:

```lua
vim.pack.add({
  -- optional, used for pretty icons
  { src = { "https://github.com/nvim-tree/nvim-web-devicons"},
  { src = "https://github.com/ATTron/neoJJ" },
})

require("neojj").setup({})

vim.keymap.set("n", "<leader>jj", "<cmd>NeoJJ<CR>")
```

## Config

The default config is below:
```lua
require("neojj").setup({
  jj_binary = "jj",           -- path to jj if it's not on PATH
  log_limit = 15,             -- how many log entries to show
  float_border = "rounded",   -- border style for popups
  popup_width = 60,

  open_mode = "current",      -- "current", "split", or "vsplit"
  split_width = 80,           -- width when using vsplit
  split_height = 20,          -- height when using split

  default_remote = "origin",           -- for push/track/fetch
  default_rebase_dest = "main@origin", -- for the quick rebase shortcut

  icons = false,              -- nerd font icons + devicons (see below)
  debug = false,              -- write debug logs (see below)
})
```

### Icons

Set `icons = true` to get nerd font icons throughout the UI:

- Section headers get contextual icons (e.g.  for working copy,  for bookmarks)
- File status gets icons instead of `[M]`/`[A]`/`[D]`/`[R]` badges
- If [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) is installed, each file also gets its language-specific icon with the correct highlight color

Requires a [Nerd Font](https://www.nerdfonts.com/) in your terminal. When `icons = false` (the default), everything uses plain text

## Getting started

Open Neovim in any jj workspace and run `:NeoJJ`

You'll see a status buffer that looks something like this:

```
▾ Working Copy (@)
Change: ksqpmoyl  Commit: abc123de
Description: Add new feature
   src/main.rs
   src/new_file.rs

▸ Diff Stat

▾ Recent Log
     ksqpmoyl  Add new feature  2 minutes ago
     ztqrpmov  Implement feature X  feature-x  1 hour ago  (parent)
     rlvkpnrz  Add error handling  main  2 hours ago

▾ Bookmarks
  main       -> rlvkpnrz
  feature-x  -> ztqrpmov  (tracked)

▾ Aliases  press x to open menu
  s   →  log --limit 10
  rb  →  rebase -d main@origin
```

From here, everything is a keypress away. Press `?` if you forget something.

## Keybindings

### Moving around

`j`/`k` move between items. `J`/`K` jump between sections. `Tab` folds/unfolds sections (works anywhere in a section, not just the header). `Enter` opens a diff. `Backspace` goes back.

### Doing things

| Key | What it does |
|-----|-------------|
| `n` | Create a new change (`jj new`) |
| `D` | Describe — opens a scratch buffer for editing |
| `s` | Squash into parent |
| `e` | Edit the change under your cursor |
| `a` | Abandon a change (asks you first) |
| `u` | Undo the last operation |
| `d` | Show the diff for whatever's under your cursor |
| `S` | Full working copy diff |
| `l` | Open the full log view |
| `gr` | Refresh everything |
| `q` | Close / go back |

### Popups

These open floating menus with more options. Hit a key to pick an action, `Esc` or `q` to bail.

| Key | Menu | What's inside |
|-----|------|--------------|
| `c` | Change | new, describe, squash, split, abandon, edit, duplicate |
| `b` | Bookmark | set, create, track, delete, advance, move, edit (switch to), list |
| `R` | Rebase | onto destination, source tree, branch, quick rebase to default |
| `f` | Git | fetch, fetch from remote, push, push bookmark, push all, export, import, list/add/remove remotes |
| `o` | Operation | undo, operation log, restore to a previous operation |
| `x` | Aliases | everything from your jj config, auto-keyed |
| `?` | Help | all keybindings in one place |

## Aliases

neoJJ reads your aliases from `jj config list aliases` — anything in `~/.jjconfig.toml`, `~/.config/jj/config.toml`, or your repo config. They show up in the `x` popup with auto-assigned keys, and as a collapsible section in the status buffer.

If an alias uses `util exec` (like a pre-commit hook or custom script), it opens in a terminal split so it can do its thing with proper I/O. Regular aliases run in the background and show output in a scratch buffer.

## Commands

| Command | What it opens |
|---------|--------------|
| `:NeoJJ` | Status buffer |
| `:NeoJJLog` | Full log with graph |
| `:NeoJJOpLog` | Operation log |
| `:NeoJJDebug` | Debug log |
| `:NeoJJDebugClear` | Clear debug log |

## Debugging

neoJJ is young. If you hit a bug, enable debug logging and include the output in your issue:

```lua
require("neojj").setup({
  debug = true,
})
```

This logs every jj command and its result to `~/.local/state/nvim/neojj.log`. Run `:NeoJJDebug` to open it, `:NeoJJDebugClear` to reset it.

## Why?

Neogit exists for git users using neovim and wanting the magit experience. I wanted something very similar to this experience but with jj workflow.

jj has a fundamentally different model; your working copy *is* a commit, there's no staging area, bookmarks replace branches, and the operation log lets you undo anything. neoJJ respects all of that

## License

MIT — see [LICENSE](LICENSE).
