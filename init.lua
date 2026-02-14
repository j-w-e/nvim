-- j-w-e's nvim config
-- (Based from MiniMax, and extensively using MINI.nvim)

-- This config is dependent on NVIM_PROFILE
--[[
      NVIM_PROFILE == 'notes' sets up blink.cmp for completion, and obsidian.nvim for notes
      Otherwise, mini.completion is used
--]]

--[[ TODO list
1. Again try to implement a todo picker for the currrent file
2. Adjust the keepcursor autocommand to not operate in MiniFiles?
3. When in markdown, on a blank line above another blank line above an unordered list, dd removes the list markers
4. Find out why following an obsidian link does not re-open file at last edited point
5. Decide if I want <leader>, or <c-,> to open FTerm
6. Sometimes, enter in markdown after a colon indents 2 spaces, not 4. Find out why?
7. Fix the insert-mode function for kk which corrects previous spelling. Currently, if no spelling mistakes exist prior to the cursor, it just breaks to insert mode and stops.
10 Replace obsidian.nvim with an alternative, eg https://github.com/magnusriga/markdown-tools.nvim or https://github.com/YousefHadder/markdown-plus.nvim
    - obsidian.nvim does not allow linking to aliases, currently
11. Work out how to get <c-l> to work to insert link from mini.pick in obsidian
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
