-- Make concise helpers for installing/adding plugins in two stages
local add, later = MiniDeps.add, MiniDeps.later
local now_if_args = _G.Config.now_if_args

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
  _G.Config.new_autocmd('FileType', filetypes, ts_start, 'Start tree-sitter')
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
    -- Map of filetype to formatters
    formatters_by_ft = {
      lua = { 'stylua' },
    },
    formatters = {
      stylua = {
        prepend_args = { '--indent-type', 'Spaces', '--indent-width', '2', '--quote-style', 'AutoPreferSingle' },
      },
    },
  })
end)

-- Notes ======================================================================

later(function()
  add('MeanderingProgrammer/render-markdown.nvim')

  require('render-markdown').setup({
    file_types = { 'markdown', 'Rmd' },
    code = {
      render_modes = { 'i' },
      style = 'full',
      border = 'thick',
    },
    html = {
      comment = {
        conceal = false,
      },
    },
  })
end)

-- R ==========================================================================

now_if_args(function()
  add('R-nvim/R.nvim')
  require('r').setup({
    R_args = { '--quiet', '--no-save' },
    hook = {
      on_filetype = function()
        local bufmap = function(mode, lhs, rhs)
          local opts = {}
          vim.api.nvim_buf_set_keymap(0, mode, lhs, rhs, opts)
        end
        bufmap('i', '<c-->', '<Plug><RInsertAssign')
        bufmap('i', '<space><space>', '<Plug><RInsertPipe')
        bufmap('i', '`', '<Plug>RmdInsertChunk')
        bufmap('n', '<Enter>', '<Plug>RDSendLine')
        bufmap('v', '<Enter>', '<Plug>RSendSelection')
        bufmap('n', '<localleader>rr', '<cmd>RMapsDesc<cr>')
        bufmap('n', '<localleader>rx', '<Plug>RClose')
        bufmap('i', '%%', ' %>%')
        bufmap('n', '<localleader><Enter>', '<Plug>RSendLine')
        bufmap('n', '<localleader>b', '<Plug>RPreviousRChunk')
        bufmap('n', '<localleader>n', '<Plug>RNextRChunk')
        bufmap('n', '<localleader>h', '<Plug>RHelp')
        bufmap('n', '<LocalLeader>rh', "<cmd>lua require('r.run').action('head', 'n', ', n = 15')<cr>")
        bufmap('n', '<LocalLeader>kx', "<cmd>lua require('r.rmd').make('pptx')<cr>")
      end,
    },
    pdfviewer = 'open',
    quarto_chunk_hl = {
      highlight = true,
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
  add('nguyenvukhang/nvim-toggler')
  require('nvim-toggler').setup({
    inverses = { ['TRUE'] = 'FALSE' },
    -- remove_default_keybinds = true,
  })
  MiniClue.set_mapping_desc('n', '<leader>i', 'Invert')
  MiniClue.set_mapping_desc('x', '<leader>i', 'Invert')
end)

later(function()
  add('samjwill/nvim-unception')
  _G.Config.new_autocmd('User', 'UnceptionEditRequestReceived', function()
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

now_if_args(function()
  add('folke/tokyonight.nvim')
  require('tokyonight').setup({
    style = 'storm',
    on_highlights = function(highlights, colors)
      highlights.FlashLabel = { bg = colors.blue0, fg = colors.magenta }
      highlights.MiniTrailspace = { fg = colors.magenta }
      highlights.CursorLine = { bg = colors.fg_gutter }
      -- highlights.RenderMarkdownCode = { bg = colors.fg_gutter }  -- this is a lighter backgroud for code blocks. I got tired of it
      highlights.RenderMarkdownCode = { bg = '#16161e' } -- this is for a dark background to code blocks
    end,
  })
  vim.cmd('colorscheme tokyonight')
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
