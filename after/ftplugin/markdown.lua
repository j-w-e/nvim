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

vim.keymap.set('n', '<localleader>sn', 'mz]s1z=`z', { buffer = 0, desc = 'fix next spelling mistake' })
vim.keymap.set('n', '<localleader>sp', 'mz[s1z=`z', { buffer = 0, desc = 'fix prev spelling mistake' })

-- -- set keymap to fix last spelling mistake. And insert an undo breakpoint right before changing spelling
-- local action = '<BS><BS><c-g>u<Esc>[s1z=gi'
-- require('mini.keymap').map_combo('i', 'kk', action)

vim.cmd([[
au BufEnter * syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")\ze\_W" keepend contained conceal contains=markdownUrl concealends
au BufEnter * hi link tkLink markdownLinkText
]])

vim.keymap.set('i', '<CR>', '<CR><cmd>AutolistNewBullet<cr>', { buffer = 0 })
vim.keymap.set('n', 'o', 'o<cmd>AutolistNewBullet<cr>', { buffer = 0 })
vim.keymap.set('n', 'O', 'O<cmd>AutolistNewBulletBefore<cr>', { buffer = 0 })
vim.keymap.set('n', '<C-r>', '<cmd>AutolistRecalculate<cr>', { buffer = 0 })

-- functions to recalculate list on edit
vim.keymap.set('n', '>>', '>><cmd>AutolistRecalculate<cr>', { buffer = 0 })
vim.keymap.set('n', '<<', '<<<cmd>AutolistRecalculate<cr>', { buffer = 0 })
vim.keymap.set('n', 'dd', 'dd<cmd>AutolistRecalculate<cr>', { buffer = 0 })
vim.keymap.set('v', 'd', 'd<cmd>AutolistRecalculate<cr>', { buffer = 0 })

local function sort_present_line()
  local prefix = 'Present: '
  local buf = 0
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  for row, line in ipairs(lines) do
    if vim.startswith(line, prefix) then
      -- Strip prefix
      local content = line:sub(#prefix + 1)
      -- Split by commas
      local items = vim.split(content, ',', { trimempty = true })
      -- Trim whitespace
      for i, v in ipairs(items) do
        items[i] = vim.trim(v)
      end
      -- Sort alphabetically
      table.sort(items)
      -- Rebuild and replace line
      local sorted = table.concat(items, ', ')
      vim.api.nvim_buf_set_lines(buf, row - 1, row, false, {
        prefix .. sorted,
      })
      -- Stop after the first match
      return
    end
  end
end

vim.keymap.set('n', '<localleader>ss', sort_present_line, { buffer = 0, desc = "Sort who's attending" })
