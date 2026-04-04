-- j-w-e's nvim config
-- (Based from MiniMax, and extensively using MINI.nvim)

-- This config is dependent on NVIM_PROFILE
--[[
      NVIM_PROFILE == 'notes' sets up blink.cmp for completion, and obsidian.nvim for notes
      Otherwise, mini.completion is used
--]]

--[[ TODO list
4. Find out why following an obsidian link does not re-open file at last edited point
5. Decide if I want <leader>, or <c-,> to open FTerm
6. Sometimes, enter in markdown after a colon indents 2 spaces, not 4. Find out why?
    - This is because treesitter incorrectly detects multiple levels of bullets as an indented code block
    - I'm actually not sure it is. It might be because lua_ls takes control of something, but I don't know what.
        - I think this, because it seems to happen more if I edit my config whilst in notes mode. Keep an eye out for it.
10 Replace obsidian.nvim with an alternative, eg https://github.com/magnusriga/markdown-tools.nvim or https://github.com/YousefHadder/markdown-plus.nvim
    - obsidian.nvim does not allow linking to aliases, currently
13. Make unception work. Currently, it just closes the terminal buffer

Notes for later tweaks:
1. I could not get <c-l> to insert a link in Obsidian, when using mini.pick. It works with snacks.picker, so I'm using that for now.
2. >> and << are both dot-repeatable on markdown headers. Except that AutoListRecalculate doesn't seem to be called as much on dot-repeat as I would expect.
      Or it's just buggy.
      See https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3 for dot-repeat info
3. Fix the insert-mode function for kk which corrects previous spelling. Currently, if no spelling mistakes exist prior to the cursor, it just breaks to insert mode and stops.
]]
--
vim.pack.add({ 'https://github.com/nvim-mini/mini.nvim' })

-- Define config table to be able to pass data between scripts
_G.Config = {}
local misc = require('mini.misc')
Config.now = function(f)
  misc.safely('now', f)
end
Config.later = function(f)
  misc.safely('later', f)
end
Config.now_if_args = vim.fn.argc(-1) > 0 and Config.now or Config.later
Config.on_event = function(ev, f)
  misc.safely('event:' .. ev, f)
end
Config.on_filetype = function(ft, f)
  misc.safely('filetype:' .. ft, f)
end

-- Define custom autocommand group and helper to create an autocommand.
local gr = vim.api.nvim_create_augroup('custom-config', {})
Config.new_autocmd = function(event, pattern, callback, desc)
  local opts = { group = gr, pattern = pattern, callback = callback, desc = desc }
  vim.api.nvim_create_autocmd(event, opts)
end

Config.on_packchanged = function(plugin_name, kinds, callback, desc)
  local f = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if not (name == plugin_name and vim.tbl_contains(kinds, kind)) then
      return
    end
    if not ev.data.active then
      vim.cmd.packadd(plugin_name)
    end
    callback()
  end
  Config.new_autocmd('PackChanged', '*', f, desc)
end

Config.conf_ver = vim.fn.getenv('NVIM_PROFILE')
