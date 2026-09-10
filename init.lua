-- ~/.config/nvim/init.lua
-- IDE-ish Neovim: file-tree sidebar, buffer tabs, fuzzy finder, syntax.
-- Single file, lazy.nvim-managed. Built for the ano repo on WSL.

--------------------------------------------------------------------------------
-- 0. Leader (must precede lazy + keymaps)
--------------------------------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- nvim-tree owns the file explorer; disable netrw so they don't fight.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

--------------------------------------------------------------------------------
-- 1. WSL clipboard bridge (preserved verbatim from the original init.lua)
--------------------------------------------------------------------------------
local paste_cmd = {
  'sh', '-c',
  'powershell.exe -NoProfile -Command "[Console]::OutputEncoding=[System.Text.UTF8Encoding]::UTF8; Get-Clipboard -Raw" | awk \'{ gsub("\\r", ""); print }\''
}
-- Copy: clip.exe reads its stdin as the OEM console code page (CP437), so it
-- mojibakes UTF-8 (Japanese/emoji) on the way to the clipboard. Read stdin as
-- UTF-8 explicitly and Set-Clipboard instead. Passed as a bare argv list (no
-- shell) so the PowerShell $vars survive unexpanded.
--
-- Set-Clipboard preserves the LF line endings it is given. Win32 edit controls
-- break lines on CRLF and ignore a bare LF, so an LF-only clipboard pastes into
-- Windows apps as a single run of text -- the whole yank is there, but it looks
-- like only the first line survived. clip.exe converts; Set-Clipboard does not.
-- Normalize to CRLF on the way out (paste_cmd strips the CRs on the way back in).
local copy_cmd = {
  'powershell.exe', '-NoProfile', '-Command',
  '$in = New-Object System.IO.StreamReader([Console]::OpenStandardInput(), [System.Text.UTF8Encoding]::new($false)); Set-Clipboard -Value $in.ReadToEnd().Replace("`r`n", "`n").Replace("`r", "`n").Replace("`n", "`r`n")'
}
vim.g.clipboard = {
  name = "WslClipboard",
  copy = { ['+'] = copy_cmd, ['*'] = copy_cmd },
  paste = { ['+'] = paste_cmd, ['*'] = paste_cmd },
  cache_enabled = 0,
}
-- clipboard left unset for performance; use "+y / "+p for the Windows clipboard.

--------------------------------------------------------------------------------
-- 2. Options
--------------------------------------------------------------------------------
local o = vim.opt
o.number = true
o.relativenumber = false
o.mouse = "a"              -- click the tree / tabs
o.termguicolors = true
o.signcolumn = "yes"
o.cursorline = true
o.wrap = true
o.linebreak = true         -- wrap at word boundaries, not mid-word
o.scrolloff = 6
o.ignorecase = true
o.smartcase = true
o.splitright = true        -- vertical splits open to the right
o.splitbelow = true
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.undofile = true
o.updatetime = 250
o.timeoutlen = 400

-- Font for GUI front-ends only (Neovide / nvim-qt). Terminal Neovim has no font of
-- its own -- it inherits Alacritty's -- so this is inert under WSL+Alacritty and
-- exists so a GUI client gets the same fallback chain, which Neovide honors
-- left-to-right. ACTIVE: IosevkaTermSlab NFM (slab, matches Alacritty) -> Symbols Nerd icons.
if vim.g.neovide or vim.fn.exists("g:GuiLoaded") == 1 then
  vim.o.guifont = "IosevkaTermSlab NFM:h14,Symbols Nerd Font Mono:h14"
  -- DISABLED -- was ACTIVE (Berkeley era): Berkeley Mono dotted-zero -> Iosevka Nerd -> Symbols.
  -- vim.o.guifont = "TX-02-Dotted0novar Medium:h14,Iosevka NFM:h14,Symbols Nerd Font Mono:h14"
end

-- .ano files get their own filetype (the spec surface language).
vim.filetype.add({ extension = { ano = "ano" } })

-- `nvim .` (or any dir) opens straight into the tree, VSCode-style.
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    if vim.fn.isdirectory(data.file) == 1 then
      vim.cmd.cd(data.file)
      require("nvim-tree.api").tree.open()
    end
  end,
})

--------------------------------------------------------------------------------
-- 3. Bootstrap lazy.nvim
--------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------------------------------------
-- 4. Plugins
--------------------------------------------------------------------------------
require("lazy").setup({
  -- Icons (needs a Nerd Font set in the terminal; falls back to text otherwise)
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- File-tree sidebar (nvim-tree, the NvChad explorer). VSCode-style: git
  -- status, indent guides, icons, mouse + keyboard nav. Toggle with Ctrl-n.
  { "nvim-tree/nvim-tree.lua",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-tree").setup({
        hijack_cursor = true,
        sync_root_with_cwd = true,
        view = { width = 32, preserve_window_proportions = true },
        renderer = {
          group_empty = true,
          highlight_git = true,
          indent_markers = { enable = true },
          icons = { show = { git = false, folder = false, file = false, folder_arrow = true } },
        },
        update_focused_file = { enable = true },      -- follow the active buffer
        -- Show everything: dotfiles and gitignored paths both stay visible.
        -- git_ignored defaults to true upstream, which hides build output and
        -- local-only trees (.claude/skills, target/) from the explorer.
        filters = { dotfiles = false, git_ignored = false },
        git = { enable = true },
        actions = { open_file = { resize_window = true } },
      })
    end },

  -- Buffer tabs across the top: every open file is a clickable tab.
  { "akinsho/bufferline.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          offsets = { { filetype = "NvimTree", text = "Explorer", separator = true } },
          separator_style = "thin",
          show_buffer_icons = false,
        },
      })
    end },

  -- Statusline
  { "nvim-lualine/lualine.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      local neutral = {
        a = { fg = "#b6bac8", bg = "#262b38", gui = "NONE" },
        b = { fg = "#b6bac8", bg = "#262b38", gui = "NONE" },
        c = { fg = "#939bac", bg = "#202430", gui = "NONE" },
      }
      require("lualine").setup({
        options = {
          theme = { normal = neutral, insert = neutral, visual = neutral,
            replace = neutral, command = neutral, inactive = neutral },
          globalstatus = true, icons_enabled = false,
          component_separators = "|", section_separators = "",
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename" },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = {
            "location",
            -- subtle, always-visible hint for the cheatsheet key (bottom-right)
            function() return "F1 help" end,
          },
        },
      })
    end },

  -- Fuzzy finder over files / grep / buffers
  { "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = "nvim-lua/plenary.nvim",
    config = function()
      require("telescope").setup({
        -- Search everything. hidden = dotfiles, no_ignore = ignore .gitignore.
        -- Gitignored-but-real files (.claude/skills) must be findable; only
        -- machine-generated trees are cut, since they bury the fuzzy ranking.
        defaults = { file_ignore_patterns = { "^%.git/", "^target/", "^%.kore/" } },
        pickers = {
          find_files = { hidden = true, no_ignore = true },
          live_grep  = { additional_args = { "--hidden", "--no-ignore" } },
        },
      })
    end },

  -- Syntax highlighting is Neovim's built-in `syntax on` (markdown/lua/bash/etc).
  -- nvim-treesitter's master branch is incompatible with nvim 0.12; skipped.

  -- Keybinding hints (press <leader> and wait to see the menu)
  { "folke/which-key.nvim", event = "VeryLazy", config = function() require("which-key").setup({}) end },
}, {
  ui = { border = "rounded" },
  change_detection = { notify = false },
})

--------------------------------------------------------------------------------
-- 5. Keymaps
--------------------------------------------------------------------------------
local map = vim.keymap.set

-- File tree (NvChad-style: Ctrl-n toggles, <leader>e focuses)
map("n", "<C-n>",     "<cmd>NvimTreeToggle<cr>", { desc = "Explorer toggle" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<cr>",  { desc = "Explorer focus" })

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>",  { desc = "Grep in files" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>",    { desc = "Open buffers" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>",   { desc = "Recent files" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>",  { desc = "Help tags" })

-- Buffers (the top tabs)
map("n", "<Tab>",      "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
map("n", "<S-Tab>",    "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
map("n", "<leader>x",  "<cmd>bdelete<cr>",             { desc = "Close buffer" })

-- Splits (see multiple files side by side)
map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split vertical" })
map("n", "<leader>sh", "<cmd>split<cr>",  { desc = "Split horizontal" })
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Save / quit / misc
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<cr>",  { desc = "Quit window" })
map("n", "<Esc>",     "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

--------------------------------------------------------------------------------
-- 6. Syntax fallback: paint otherwise-unhighlighted buffers as Haskell.
--    Niche languages (.ano, no-extension files) get pretty colors instead of
--    plain text. Precedence, highest first:
--      LSP semantic tokens  >  treesitter  >  native syntax/<ft>.vim  >  Haskell
--    A buffer only gets Haskell when nothing above it is already highlighting it.
--------------------------------------------------------------------------------
local function ts_highlighting(buf)
  local ok, hl = pcall(require, "vim.treesitter.highlighter")
  return ok and hl.active[buf] ~= nil
end

local function haskell_fallback(buf)
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then return end
  if vim.bo[buf].buftype ~= "" then return end                 -- tree/prompt/help/qf: skip
  if vim.bo[buf].filetype == "haskell" then return end          -- already Haskell
  if #vim.lsp.get_clients({ bufnr = buf }) > 0 then return end  -- a language server owns it
  if ts_highlighting(buf) then return end                       -- treesitter is on it
  local cur = vim.b[buf].current_syntax
  if cur and cur ~= "" then return end                          -- a real syntax file loaded
  vim.bo[buf].syntax = "haskell"                                -- nothing else: Haskell colors
end

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
  desc = "Haskell syntax as a fallback for unhighlighted buffers",
  callback = function(args) vim.schedule(function() haskell_fallback(args.buf) end) end,
})

--------------------------------------------------------------------------------
-- 7. Integrated terminal: a toggleable bottom panel (VSCode-style).
--    <leader>t opens/hides it; Ctrl-t hides it from inside; the shell session
--    keeps running while hidden. <C-\><C-n> drops to normal mode to scroll.
--------------------------------------------------------------------------------
local term = { buf = -1, win = -1 }
local function toggle_term()
  if vim.api.nvim_win_is_valid(term.win) then
    vim.api.nvim_win_hide(term.win)
    return
  end
  if not vim.api.nvim_buf_is_valid(term.buf) then
    term.buf = vim.api.nvim_create_buf(false, true)
  end
  vim.cmd("botright split")
  vim.api.nvim_win_set_height(0, 14)
  term.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(term.win, term.buf)
  if vim.bo[term.buf].buftype ~= "terminal" then
    vim.fn.jobstart(vim.o.shell, { term = true })   -- nvim 0.11+ replacement for termopen
  end
  vim.cmd("startinsert")
end
map("n", "<leader>t", toggle_term, { desc = "Terminal toggle" })
map("t", "<C-t>",     toggle_term, { desc = "Terminal hide" })

vim.api.nvim_create_autocmd("TermOpen", {
  desc = "No gutter clutter inside the terminal",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

--------------------------------------------------------------------------------
-- 8. Cheatsheet: a floating quick-reference for every custom key. F1 or <leader>?.
--------------------------------------------------------------------------------
local cheats = {
  { "File tree", {
    { "Ctrl-n",         "toggle explorer" },
    { "<leader>e",      "focus explorer" },
    { "(in tree) g?",   "all tree keys" },
  } },
  { "Find", {
    { "<leader>ff",     "find files" },
    { "<leader>fg",     "grep in files" },
    { "<leader>fb",     "open buffers" },
    { "<leader>fr",     "recent files" },
    { "<leader>fh",     "help tags" },
  } },
  { "Buffers / tabs", {
    { "Tab / S-Tab",    "next / prev buffer" },
    { "<leader>x",      "close buffer" },
  } },
  { "Windows", {
    { "<leader>sv",     "split vertical" },
    { "<leader>sh",     "split horizontal" },
    { "Ctrl-h/j/k/l",   "move between splits" },
  } },
  { "Terminal", {
    { "<leader>t",      "toggle terminal" },
    { "Ctrl-t",         "hide terminal (from inside)" },
    { "Ctrl-\\ Ctrl-n", "terminal -> normal mode" },
  } },
  { "Appearance", {
    { "<leader>ut",     "reload C64 Brutalist theme" },
  } },
  { "General", {
    { "<leader>w",      "save" },
    { "<leader>q",      "quit window" },
    { "Esc",            "clear search highlight" },
    { "F1 / <leader>?", "this cheatsheet" },
  } },
}

local function show_cheats()
  local lines, tag = {}, {}
  table.insert(lines, "  Neovim cheatsheet   (leader = Space)")
  tag[1] = "Title"
  table.insert(lines, "")
  for _, section in ipairs(cheats) do
    table.insert(lines, "  " .. section[1])
    tag[#lines] = "Function"
    for _, item in ipairs(section[2]) do
      table.insert(lines, string.format("    %-16s  %s", item[1], item[2]))
    end
    table.insert(lines, "")
  end
  table.insert(lines, "  q / Esc to close")
  tag[#lines] = "Comment"

  local width = 0
  for _, l in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(l)) end
  width = width + 2
  local height = #lines

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  local ns = vim.api.nvim_create_namespace("cheats")
  for line, group in pairs(tag) do
    vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, { end_col = #lines[line], hl_group = group })
  end
  for i, l in ipairs(lines) do            -- accent the key column of each binding row
    if l:match("^%s%s%s%s%S") then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 4, { end_col = math.min(20, #l), hl_group = "Constant" })
    end
  end
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", style = "minimal", border = "rounded",
    width = width, height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    title = " cheatsheet ", title_pos = "center",
  })
  vim.wo[win].cursorline = true
  for _, k in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", k, "<cmd>close<cr>", { buffer = buf, nowait = true })
  end
end
map("n", "<F1>",      show_cheats, { desc = "Cheatsheet" })
map("n", "<leader>?", show_cheats, { desc = "Cheatsheet" })

--------------------------------------------------------------------------------
-- 9. One active theme, shared with Vim; old saved selections cannot override it.
--------------------------------------------------------------------------------
local function apply_theme()
  vim.cmd.colorscheme("c64-brutalist")
end
map("n", "<leader>ut", apply_theme, { desc = "Reload C64 Brutalist theme" })
apply_theme()
