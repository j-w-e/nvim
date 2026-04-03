-- Make concise helpers for installing/adding plugins in two stages
local add = vim.pack.add
local now, now_if_args, later = Config.now, Config.now_if_args, Config.later

-- Tree-sitter ================================================================

now_if_args(function()
  local ts_update = function()
    vim.cmd('TSUpdate')
  end
  Config.on_packchanged('nvim-treesitter', { 'update' }, ts_update, ':TSUpdate')
  add({
    'https://github.com/nvim-treesitter/nvim-treesitter',
    'https://github.com/nvim-treesitter/nvim-treesitter-textobjects',
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
  add({ 'https://github.com/neovim/nvim-lspconfig' })
  vim.lsp.enable({
    'lua_ls',
  })
end)

-- Formatting =================================================================

later(function()
  add({ 'https://github.com/stevearc/conform.nvim' })

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
--   add({ 'https://github.com/mason-org/mason.nvim' })
--   require('mason').setup()
-- end)

later(function()
  add({ 'https://github.com/numToStr/FTerm.nvim' })
end)

later(function()
  add({ 'https://github.com/folke/flash.nvim' })
  require('flash').setup({
    labels = 'enaiohtsrluypfwmdgc',
    search = { mode = 'search' },
    modes = {
      char = {
        enabled = false,
        -- char_actions = function()
        --   return {
        --     [';'] = 'prev',
        --     [','] = 'next',
        --   }
        -- end,
      },
    },
  })
end)

later(function()
  add({ 'https://github.com/nat-418/boole.nvim' })
  require('boole').setup({
    mappings = {
      increment = '<C-a>',
      decrement = '<C-/>',
    },
  })
end)

later(function()
  add({ 'https://github.com/samjwill/nvim-unception' })
  Config.new_autocmd('User', 'UnceptionEditRequestReceived', function()
    require('FTerm').toggle()
  end, 'Close FTerm on vimception')
end)

later(function()
  add({ 'https://github.com/romainl/vim-cool' })
end)

later(function()
  add({ 'https://github.com/folke/zen-mode.nvim' })
  require('zen-mode').setup({
    window = { width = 150 },
  })
end)

later(function()
  add({ 'https://github.com/folke/todo-comments.nvim' })
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
  add({ 'https://github.com/gaodean/autolist.nvim' })
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
  add({ 'https://github.com/rlychrisg/keepcursor.nvim' })
  require('keepcursor').setup({
    enabled_on_start_v = 'middle', -- options are "top", "middle" and "bottom".
    enabled_on_start_h = 'none', -- options are "left" and "right".
  })
  local keepcursor_state = {
    mode = nil, -- "top" | "mid" | "bot"
  }

  -- Helper: extract mode from KeepCursorStatus()
  local function get_keepcursor_mode()
    local ok, status = pcall(vim.fn.KeepCursorStatus)
    if not ok or type(status) ~= 'string' then
      return nil
    end

    status = status:lower()

    if status:find('top') then
      return 'top'
    elseif status:find('mid') then
      return 'mid'
    elseif status:find('bot') then
      return 'bot'
    end

    return nil
  end

  -- Helper: restore mode
  local function restore_keepcursor(mode)
    if mode == 'top' then
      vim.cmd('ToggleCursorTop')
    elseif mode == 'mid' then
      vim.cmd('ToggleCursorMid')
    elseif mode == 'bot' then
      vim.cmd('ToggleCursorBot')
    end
  end

  -- Enter mini.files → save + disable
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'minifiles',
    callback = function()
      keepcursor_state.mode = get_keepcursor_mode()

      -- Disable keepcursor (usually toggle command)
      vim.cmd('DisableKeepCursor')
    end,
  })

  -- Leave mini.files → restore
  vim.api.nvim_create_autocmd('BufLeave', {
    callback = function(args)
      if vim.bo[args.buf].filetype ~= 'minifiles' then
        return
      end

      if keepcursor_state.mode then
        restore_keepcursor(keepcursor_state.mode)
        keepcursor_state.mode = nil
      end
    end,
  })
end)

later(function()
  add({ 'https://github.com/Aasim-A/scrollEOF.nvim' })
  require('scrollEOF').setup({
    floating = false,
    insert_mode = true,
    disabled_filetypes = { 'minifiles' },
  })
end)

later(function()
  add({ 'https://github.com/mawkler/demicolon.nvim' })
  require('demicolon').setup({
    keymaps = {
      horizontal_motions = false,
      -- repeat_motions = 'stateful', -- Don't create ; and , keymaps
      repeat_motions = false, -- Don't create ; and , keymaps
    },
  })

  local map, nxo = vim.keymap.set, { 'n', 'x', 'o' }

  map(nxo, ',', require('demicolon.repeat_jump').next)
  map(nxo, ';', require('demicolon.repeat_jump').prev)

  local flash_char = require('flash.plugins.char')
  ---@param options { key: string, fowrard: boolean }
  local function flash_jump(options)
    return function()
      require('demicolon.jump').repeatably_do(function(o)
        local key = o.forward and o.key:lower() or o.key:upper()

        flash_char.jumping = true
        local autohide = require('flash.config').get('char').autohide

        -- Originally was
        -- if require("flash.repeat").is_repeat then
        if o.repeated then
          flash_char.jump_labels = false

          -- Originally was
          -- flash_char.state:jump({ count = vim.v.count1 })
          if o.forward then
            flash_char.right()
          else
            flash_char.left()
          end

          flash_char.state:show()
        else
          flash_char.jump(key)
        end

        vim.schedule(function()
          flash_char.jumping = false
          if flash_char.state and autohide then
            flash_char.state:hide()
          end
        end)
      end, options)
    end
  end

  vim.api.nvim_create_autocmd({ 'BufLeave', 'CursorMoved', 'InsertEnter' }, {
    group = vim.api.nvim_create_augroup('flash_char', { clear = true }),
    callback = function(event)
      local hide = event.event == 'InsertEnter' or not flash_char.jumping
      if hide and flash_char.state then
        flash_char.state:hide()
      end
    end,
  })

  vim.on_key(function(key)
    if flash_char.state and key == require('flash.util').ESC and (vim.fn.mode() == 'n' or vim.fn.mode() == 'v') then
      flash_char.state:hide()
    end
  end)

  vim.keymap.set({ 'n', 'x', 'o' }, 'f', flash_jump({ key = 'f', forward = true }), { desc = 'Flash f' })
  vim.keymap.set({ 'n', 'x', 'o' }, 'F', flash_jump({ key = 'F', forward = false }), { desc = 'Flash F' })
  vim.keymap.set({ 'n', 'x', 'o' }, 't', flash_jump({ key = 't', forward = true }), { desc = 'Flash t' })
  vim.keymap.set({ 'n', 'x', 'o' }, 'T', flash_jump({ key = 'T', forward = false }), { desc = 'Flash T' })

  local function todo_jump(options)
    return function()
      require('demicolon.jump').repeatably_do(function(o)
        local forward = o.forward
        if forward then
          require('todo-comments').jump_next()
        else
          require('todo-comments').jump_prev()
        end
      end, options)
    end
  end
  vim.keymap.set({ 'n', 'x', 'o' }, '[t', todo_jump({ forward = false }))
  vim.keymap.set({ 'n', 'x', 'o' }, ']t', todo_jump({ forward = true }))
end)

-- later(function()
--     add({ 'https://github.com/hat0uma/csvview.nvim' })
--     require('csvview').setup()
-- end)
