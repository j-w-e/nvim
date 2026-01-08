-- j-w-e's nvim config
-- (Based from MiniMax, and extensively using MINI.nvim)

--[[ TODO list
1. Find out if I can use Obsidian.nvim with mini.completion.
  - Or just use blink.cmp / cmp.nvim, for just obsidian files
  - Or use two versions of my nvim config, one with blink (just for notes) and one with mini.completion
2. Find out why R.nvim doesn't respect <bs> as a localleader.
3. Remap U and <c-r> to undo.
5. Set up the 'core' label for key notes eg team.
8. Decide if I want <leader>, or <c-,> to open FTerm
10. Set up markdown formatting on save, or just trimming trailspace, on save
11. Write a better mini.pick todo_picker
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
