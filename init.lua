-- j-w-e's nvim config
-- (Based from MiniMax, and extensively using MINI.nvim)

-- This config exists in two branches simultaneously. The main branch uses mini.completion.
-- The 'blink' branch uses blink.cmp, for the moment, in order to have completion for obsidian.nvim.
-- using NVIM-APPNAME=blink, I run nvim with a specific config depending on whether I am using obsidian or not.

--[[ TODO list
2. Find out why R.nvim doesn't respect <bs> as a localleader.
8. Decide if I want <leader>, or <c-,> to open FTerm
11. Write a better mini.pick todo_picker
12. Set up a plugin to format markdown / comment bullets
13. Set up a keymap to find TODOs in the current file, sorted by line number. This should be possible with https://nvim-mini.org/mini.nvim/doc/mini-extra.html#miniextra.pickers.buf_lines
]]
--
-- Bootstrap 'mini.nvim' manually in a way that it gets managed by 'mini.deps'
local mini_path = vim.fn.stdpath('data') .. '/site/pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local origin = 'https://github.com/nvim-mini/mini.nvim'
  local clone_cmd = { 'git', 'clone', '--filter=blob:none', origin, mini_path }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Plugin manager. Set up immediately for `now()`/`later()` helpers.
-- Example usage:
-- - `MiniDeps.add('...')` - use inside config to add a plugin
-- - `:DepsUpdate` - update all plugins
-- - `:DepsSnapSave` - save a snapshot of currently active plugins
require('mini.deps').setup()

-- Define config table to be able to pass data between scripts
_G.Config = {}

-- Define custom autocommand group and helper to create an autocommand.
local gr = vim.api.nvim_create_augroup('custom-config', {})
_G.Config.new_autocmd = function(event, pattern, callback, desc)
  local opts = { group = gr, pattern = pattern, callback = callback, desc = desc }
  vim.api.nvim_create_autocmd(event, opts)
end

-- Some plugins and 'mini.nvim' modules only need setup during startup if Neovim
-- is started like `nvim -- path/to/file`, otherwise delaying setup is fine
_G.Config.now_if_args = vim.fn.argc(-1) > 0 and MiniDeps.now or MiniDeps.later
