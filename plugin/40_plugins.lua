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
      ['*'] = { 'trim_whitespace' },
    },
    formatters = {
      stylua = {
        prepend_args = { '--indent-type', 'Spaces', '--indent-width', '2', '--quote-style', 'AutoPreferSingle' },
      },
    },
    format_on_save = {
      lsp_format = 'fallback',
      timeout_ms = 500,
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

later(function()
  add({ source = 'obsidian-nvim/obsidian.nvim', checkout = 'f513608b6a413d82cb228bba0179a36190b22d21' })
  require('obsidian').setup({
    legacy_commands = false,
    ui = { enable = false },
    checkbox = { create_new = false },
    workspaces = {
      {
        name = 'work',
        path = vim.fn.expand('~/Documents/Work/OneDrive - Norwegian Refugee Council/notes'),
      },
      {
        name = 'personal',
        path = vim.fn.expand('~/Documents/personal/notes'),
        overrides = {
          templates = {
            folder = vim.NIL,
          },
          notes_subdir = vim.NIL,
        },
      },
    },
    new_notes_location = 'notes_subdir',
    notes_subdir = 'meetings',
    search = { sort_by = 'path' },

    note_id_func = function(title)
      -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
      -- In this case a note with the title 'My new note' will be given an ID that looks
      -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
      local suffix = ''
      if title ~= nil then
        -- If title is given, transform it into valid file name.
        suffix = title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
      else
        -- If title is nil, just add 4 random uppercase letters to the suffix.
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.date('%y%m%d')) .. '-' .. suffix
    end,

    frontmatter = {
      enable = true,
      func = function(note)
        -- Add the title of the note as an alias.
        if note.title then
          note:add_alias(note.title)
        end

        local out = { id = note.id, aliases = note.aliases, tags = note.tags, area = '' }

        -- `note.metadata` contains any manually added fields in the frontmatter.
        -- So here we just make sure those fields are kept in the frontmatter.
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end

        return out
      end,
    },

    templates = {
      folder = 'templates',
      date_format = '%Y-%m-%d-%a',
      time_format = '%H:%M',
    },
    follow_url_func = function(url)
      -- Open the URL in the default web browser.
      vim.fn.jobstart({ 'open', url }) -- Mac OS
      -- vim.fn.jobstart({"xdg-open", url})  -- linux
      -- vim.cmd(':silent exec "!start ' .. url .. '"') -- Windows
      -- vim.ui.open(url) -- need Neovim 0.10.0+
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
