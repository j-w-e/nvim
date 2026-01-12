-- ┌─────────────────────────┐
-- │ Filetype config example │
-- └─────────────────────────┘
--
-- This is an example of a configuration that will apply only to a particular
-- filetype, which is the same as file's basename ('markdown' in this example;
-- which is for '*.md' files).
--
-- It can contain any code which will be usually executed when the file is opened
-- (strictly speaking, on every 'filetype' option value change to target value).
-- Usually it needs to define buffer/window local options and variables.
-- So instead of `vim.o` to set options, use `vim.bo` for buffer-local options and
-- `vim.cmd('setlocal ...')` for window-local options (currently more robust).
--
-- This is also a good place to set buffer-local 'mini.nvim' variables.
-- See `:h mini.nvim-buffer-local-config` and `:h mini.nvim-disabling-recipes`.

-- Enable spelling and wrap for window
vim.cmd('setlocal spell wrap')

-- Fold with tree-sitter
vim.cmd('setlocal foldmethod=expr foldexpr=v:lua.vim.treesitter.foldexpr()')

-- Disable built-in `gO` mapping in favor of 'mini.basics'
vim.keymap.del('n', 'gO', { buffer = 0 })

-- Set indent scope to only contain top border
vim.b.miniindentscope_config = { options = { border = 'top' } }

-- Treat numbers as negative only if preceded by a whitespace
-- So that dates (2026-01-12) does not get counted as negative
vim.opt_local.nrformats = 'blank'

-- Set markdown-specific surrounding in 'mini.surround'
vim.b.minisurround_config = {
  custom_surroundings = {
    s = {
      input = { '%~%~().-()%~%~' },
      output = { left = '~~', right = '~~' },
    },
    i = {
      input = { '%*().-()%*' },
      output = { left = '*', right = '*' },
    },
    b = {
      input = { '%*%*().-()%*%*' },
      output = { left = '**', right = '**' },
    },
    -- Markdown link. Common usage:
    -- `saiwL` + [type/paste link] + <CR> - add link
    -- `sdL` - delete link
    -- `srLL` + [type/paste link] + <CR> - replace link
    L = {
      input = { '%[().-()%]%(.-%)' },
      output = function()
        local link = require('mini.surround').user_input('Link: ')
        return { left = '[', right = '](' .. link .. ')' }
      end,
    },
  },
}

vim.keymap.set('n', 'ss', 'sairs', { buffer = 0, desc = 'strikeout current line', remap = true })

-- set keymap to fix last spelling mistake. And insert an undo breakpoint right before changing spelling
local action = '<BS><BS><c-g>u<Esc>[s1z=gi<Right>'
require('mini.keymap').map_combo('i', 'kk', action)

vim.cmd [[
au BufEnter * syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")\ze\_W" keepend contained conceal contains=markdownUrl concealends
au BufEnter * hi link tkLink markdownLinkText
]]

