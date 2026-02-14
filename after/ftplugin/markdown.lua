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

local function fix_spelling(direction)
  local ns = vim.api.nvim_create_namespace('spell_fix_highlight')
  local bufnr = vim.api.nvim_get_current_buf()
  -- Save cursor position
  local original_pos = vim.api.nvim_win_get_cursor(0)
  -- Go to appropriate spelling mistake
  if direction == 'next' then
    vim.cmd('normal! ]s')
  else
    vim.cmd('normal! [s')
  end
  -- Get word range BEFORE correction
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local word = vim.fn.expand('<cword>')
  local start_col = col
  local end_col = col + #word
  -- Apply first suggestion
  vim.cmd('normal! 1z=')
  -- Get corrected word length
  local new_word = vim.fn.expand('<cword>')
  end_col = start_col + #new_word
  -- Clear old highlight
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  -- Highlight corrected word
  vim.highlight.range(bufnr, ns, 'IncSearch', { row - 1, start_col }, { row - 1, end_col }, { inclusive = false })
  -- Clear highlighting after 300ms
  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end, 300)
  -- Return to original position
  vim.api.nvim_win_set_cursor(0, original_pos)
end
local fix_next_spelling = function()
  fix_spelling('next')
end
vim.keymap.set('n', '<localleader>sp', fix_spelling, { buffer = 0, desc = 'fix prev spelling mistake' })
vim.keymap.set('n', '<localleader>sn', fix_next_spelling, { buffer = 0, desc = 'fix next spelling mistake' })

vim.cmd([[
au BufEnter * syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")\ze\_W" keepend contained conceal contains=markdownUrl concealends
au BufEnter * hi link tkLink markdownLinkText
]])

vim.keymap.set('i', '<CR>', '<CR><cmd>AutolistNewBullet<cr>', { buffer = 0 })
vim.keymap.set('n', 'o', 'o<cmd>AutolistNewBullet<cr>', { buffer = 0 })
vim.keymap.set('n', 'O', 'O<cmd>AutolistNewBulletBefore<cr>', { buffer = 0 })
vim.keymap.set('n', '<C-r>', '<cmd>AutolistRecalculate<cr>', { buffer = 0 })

-- functions to recalculate list on edit
vim.keymap.set('n', '>>', function()
  local line = vim.api.nvim_get_current_line()
  if line:match('^#') then
    -- Add an extra # at the start of the line
    vim.api.nvim_set_current_line('#' .. line)
  else
    -- Fallback to normal >> and then run AutolistRecalculate
    vim.cmd('normal! >>')
    vim.cmd('AutolistRecalculate')
  end
end, { noremap = true, silent = true })
vim.keymap.set('n', '<<', function()
  local line = vim.api.nvim_get_current_line()
  -- Match leading #'s
  local hashes = line:match('^(#+)')
  if hashes then
    if #hashes > 1 then
      -- Remove exactly one leading #
      vim.api.nvim_set_current_line(line:sub(2))
    end
    -- If there's only one #, do nothing (never remove the last one)
  else
    -- Fallback to normal << and then run AutolistRecalculate
    vim.cmd('normal! <<')
    vim.cmd('AutolistRecalculate')
  end
end, { noremap = true, silent = true })
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
