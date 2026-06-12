-- Make concise helpers for installing/adding plugins in two stages
local add = vim.pack.add
local now, now_if_args, later = Config.now, Config.now_if_args, Config.later

-- Tree-sitter ================================================================

now_if_args(function()
  add({ 'https://github.com/romus204/tree-sitter-manager.nvim' })
  local languages = {
    'csv',
    'lua',
    'vimdoc',
    'markdown',
    'markdown_inline',
    'r',
    'rnoweb',
    'yaml',
    'zsh',
  }
  require('tree-sitter-manager').setup({
    -- Default Options
    ensure_installed = languages, -- list of parsers to install at the start of a neovim session
    -- border = nil, -- border style for the window (e.g. "rounded", "single"), if nil, use the default border style defined by 'vim.o.winborder'. See :h 'winborder' for more info.
    -- auto_install = false, -- if enabled, install missing parsers when editing a new file
    highlight = true, -- treesitter highlighting is enabled by default
    -- languages = {}, -- override or add new parser sources
    -- parser_dir = vim.fn.stdpath("data") .. "/site/parser",
    -- query_dir = vim.fn.stdpath("data") .. "/site/queries",
  })
end)

-- R ==========================================================================

now_if_args(function()
  add({ 'https://github.com/R-nvim/R.nvim' })
  require('r').setup({
    R_args = { '--quiet', '--no-save' },
    hook = {
      on_filetype = function()
        local bufmap = function(mode, lhs, rhs, desc)
          desc = desc or ''
          vim.api.nvim_buf_set_keymap(0, mode, lhs, rhs, { desc = desc })
        end
        bufmap('i', '<c-->', '<Plug>RInsertAssign')
        bufmap('i', '<space><space>', '<Plug>RInsertPipe')
        bufmap('i', '`', '<Plug>RmdInsertChunk')
        bufmap('n', '<Enter>', '<Plug>RDSendLine')
        bufmap('v', '<Enter>', '<Plug>RSendSelection')
        bufmap('n', '<localleader>rr', '<cmd>RMapsDesc<cr>', 'R mappings')
        bufmap('n', '<localleader>rx', '<Plug>RClose', 'Close R')
        bufmap('i', '%%', ' %>%')
        bufmap('n', '<localleader><enter>', '<Plug>RSendLine', 'Send line and stay')
        bufmap('n', '<localleader>N', '<Plug>RPreviousRChunk', 'Go to previous chunk')
        bufmap('n', '<localleader>n', '<Plug>RNextRChunk', 'Go to next chunk')
        bufmap('n', '<localleader>h', '<Plug>RHelp', 'R help')
        bufmap(
          'n',
          '<LocalLeader>rh',
          "<cmd>lua require('r.run').action('head', 'n', ', n = 15')<cr>",
          'head() on <cword>'
        )
        bufmap('n', '<LocalLeader>kx', "<cmd>lua require('r.rmd').make('pptx')<cr>", 'Knit pptx')
      end,
    },
    pdfviewer = 'open',
    chunk_hl = {
      highlight = false,
      virtual_title = true,
      events = '',
    },
  })
end)
