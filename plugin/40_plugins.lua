-- Make concise helpers for installing/adding plugins in two stages
local add, later = MiniDeps.add, MiniDeps.later
local now_if_args = Config.now_if_args

-- Tree-sitter ================================================================

now_if_args(function()
  add({
    source = 'nvim-treesitter/nvim-treesitter',
    -- Update tree-sitter parser after plugin is updated
    hooks = {
      post_checkout = function()
        vim.cmd('TSUpdate')
      end,
    },
  })
  add({
    source = 'nvim-treesitter/nvim-treesitter-textobjects',
    -- Use `main` branch since `master` branch is frozen, yet still default
    -- It is needed for compatibility with 'nvim-treesitter' `main` branch
    checkout = 'main',
  })

  -- Define languages which will have parsers installed and auto enabled
  local languages = {
    'lua',
    'vimdoc',
    'markdown',
    'markdown_inline',
    'r',
    'rnoweb',
    'yaml',
    'zsh',
  }
  local isnt_installed = function(lang)
    return #vim.api.nvim_get_runtime_file('parser/' .. lang .. '.*', false) == 0
  end
  local to_install = vim.tbl_filter(isnt_installed, languages)
  if #to_install > 0 then
    require('nvim-treesitter').install(to_install)
  end

  -- Enable tree-sitter after opening a file for a target language
  local filetypes = {}
  for _, lang in ipairs(languages) do
    for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
      table.insert(filetypes, ft)
    end
  end
  local ts_start = function(ev)
    vim.treesitter.start(ev.buf)
  end
  Config.new_autocmd('FileType', filetypes, ts_start, 'Start tree-sitter')
end)

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
now_if_args(function()
  add('neovim/nvim-lspconfig')
  vim.lsp.enable({
    'lua_ls',
  })
end)

-- Formatting =================================================================

later(function()
  add('stevearc/conform.nvim')

  require('conform').setup({
    default_format_opts = {
      -- Allow formatting from LSP server if no dedicated formatter is available
      lsp_format = 'fallback',
    },
    -- Map of filetype to formatters
    formatters_by_ft = {
      lua = { 'stylua' },
      quarto = { 'styler' },
      r = { 'styler' },
      -- rmd = { 'styler' },
      ['*'] = { 'trim_whitespace' },
    },
    formatters = {
      stylua = {
        prepend_args = { '--indent-type', 'Spaces', '--indent-width', '2', '--quote-style', 'AutoPreferSingle' },
      },
    },
    format_on_save = function(bufnr)
      -- Disable with a global or buffer-local variable
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      -- Disable autoformat on certain filetypes
      local slow_filetypes = { 'quarto', 'r', 'qmd', 'rmd' }
      if vim.tbl_contains(slow_filetypes, vim.bo[bufnr].filetype) then
        return { timeout_ms = 3000, lsp_format = 'fallback' }
      end
      return { timeout_ms = 500, lsp_format = 'fallback' }
    end,
  })
end)

-- R ==========================================================================

now_if_args(function()
  add('R-nvim/R.nvim')
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
    quarto_chunk_hl = {
      highlight = false,
      virtual_title = true,
      events = '',
    },
  })
end)

-- Other ======================================================================

-- TODO I installed stylua and lua-language-server from brew
-- It may make more sense to install them from Mason
-- now_if_args(function()
--   add('mason-org/mason.nvim')
--   require('mason').setup()
-- end)

later(function()
  add('numToStr/FTerm.nvim')
end)

later(function()
  add('folke/flash.nvim')
  require('flash').setup({
    labels = 'enaiohtsrluypfwmdgc',
    search = { mode = 'search' },
    modes = {
      char = {
        char_actions = function()
          return {
            [';'] = 'prev',
            [','] = 'next',
          }
        end,
      },
    },
  })
end)

later(function()
  add('nat-418/boole.nvim')
  require('boole').setup({
    mappings = {
      increment = '<C-a>',
      decrement = '<C-x>',
    },
  })
end)

later(function()
  add('samjwill/nvim-unception')
  Config.new_autocmd('User', 'UnceptionEditRequestReceived', function()
    require('FTerm').toggle()
  end, 'Close FTerm on vimception')
end)

later(function()
  add('romainl/vim-cool')
end)

later(function()
  add('folke/zen-mode.nvim')
  require('zen-mode').setup({
    window = { width = 150 },
  })
end)

later(function()
  add('folke/todo-comments.nvim')
  require('todo-comments').setup({
    signs = true, -- show icons in the signs column
    sign_priority = 8, -- sign priority
    -- keywords recognized as todo comments
    keywords = {
      TODO = { icon = '', color = 'info' },
    },
    merge_keywords = false, -- when true, custom keywords will be merged with the defaults
    -- highlighting of the line containing the todo comment
    -- * before: highlights before the keyword (typically comment characters)
    -- * keyword: highlights of the keyword
    -- * after: highlights after the keyword (todo text)
    highlight = {
      before = '', -- "fg" or "bg" or empty
      keyword = '', -- "fg", "bg", "wide", "wide_bg", "wide_fg" or empty. (wide and wide_bg is the same as bg, but will also highlight surrounding characters, wide_fg acts accordingly but with fg)
      after = '', -- "fg" or "bg" or empty
      pattern = [[.*<(KEYWORDS)\s*]], -- pattern or table of patterns, used for highlighting (vim regex)
      comments_only = false, -- uses treesitter to match keywords in comments only
    },
    search = {
      pattern = [[\b(KEYWORDS)\b]], -- match without the extra colon. You'll likely get false positives
    },
  })
end)

later(function()
  add({ source = 'chrishrb/gx.nvim', depends = { 'nvim-lua/plenary.nvim' } })
  require('gx').setup({
    select_prompt = false,
    handlers = {
      search = false,
    },
  })
end)

later(function()
  add('gaodean/autolist.nvim')
  local list_patterns = {
    unordered = '[-+*]', -- - + *
    digit = '%d+[.)]', -- 1. 2. 3.
    ascii = '%a[.)]', -- a) b) c)
    roman = '%u*[.)]', -- I. II. III.
  }
  require('autolist').setup({
    enabled = true,
    colon = { -- if a line ends in a colon
      indent = true, -- if in list and line ends in `:` then create list
      indent_raw = true, -- above, but doesn't need to be in a list to work
      preferred = '-', -- what the new list starts with (can be `1.` etc)
    },
    cycle = { -- Cycles the list type in order
      '-', -- whatever you put here will match the first item in your list
      '*', -- for example if your list started with a `-` it would go to `*`
      '1.', -- this says that if your list starts with a `*` it would go to `1.`
      '1)', -- this all leverages the power of recalculate.
      'a)', -- i spent many hours on that function
      'I.', -- try it, change the first bullet in a list to `a)`, and press recalculate
    },
    lists = { -- configures list behaviours
      markdown = {
        list_patterns.unordered,
        list_patterns.digit,
        list_patterns.ascii, -- for example this specifies activate the ascii list
        list_patterns.roman, -- type for markdown files.
      },
      text = {
        list_patterns.unordered,
        list_patterns.digit,
        list_patterns.ascii,
        list_patterns.roman,
      },
    },
  })
end)

later(function()
  add('rlychrisg/keepcursor.nvim')
  require('keepcursor').setup({
    enabled_on_start_v = 'middle', -- options are "top", "middle" and "bottom".
    enabled_on_start_h = 'none', -- options are "left" and "right".
  })
end)

later(function()
  add('Aasim-A/scrollEOF.nvim')
  require('scrollEOF').setup({
    floating = false,
    insert_mode = true,
  })
end)

-- later(function()
--   add('mawkler/demicolon.nvim')
--   require('demicolon').setup({
--     keymaps = {
--       repeat_motions = false, -- Don't create ; and , keymaps
--     },
--   })
--
--   local map, nxo = vim.keymap.set, { 'n', 'x', 'o' }
--
--   -- Stateless: always forward/backward
--   -- map(nxo, 'n', require('demicolon.repeat_jump').forward)
--   -- map(nxo, 'N', require('demicolon.repeat_jump').backward)
--
--   -- Or, stateful (remember the original motion’s direction)
--   map(nxo, ',', require('demicolon.repeat_jump').next)
--   map(nxo, ';', require('demicolon.repeat_jump').prev)
-- end)

-- later(function()
--     add('hat0uma/csvview.nvim')
--     require('csvview').setup()
-- end)
