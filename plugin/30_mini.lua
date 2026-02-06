-- To minimize the time until first screen draw, modules are enabled in two steps:
-- - Step one enables everything that is needed for first draw with `now()`.
--   Sometimes is needed only if Neovim is started as `nvim -- path/to/file`.
-- - Everything else is delayed until the first draw with `later()`.
local now, later = MiniDeps.now, MiniDeps.later
local now_if_args = _G.Config.now_if_args

local conf_ver = vim.fn.getenv('NVIM_PROFILE')

-- Step one ===================================================================

-- Common configuration presets.
now(function()
  require('mini.basics').setup({
    -- Manage options in 'plugin/10_options.lua' for didactic purposes
    options = { basic = false },
    mappings = {
      option_toggle_prefix = '<leader>vt',
      -- Create `<C-hjkl>` mappings for window navigation
      windows = true,
      -- Create `<M-hjkl>` mappings for navigation in Insert and Command modes
      move_with_alt = false,
    },
  })
end)

now(function()
  require('mini.icons').setup({})
  -- Not needed for 'mini.nvim' or MiniMax, but might be useful for others.
  later(MiniIcons.mock_nvim_web_devicons)
  -- Add LSP kind icons. Useful for 'mini.completion'.
  later(MiniIcons.tweak_lsp_kind)
end)

-- Miscellaneous small but useful functions.
now_if_args(function()
  -- Makes `:h MiniMisc.put()` and `:h MiniMisc.put_text()` public
  require('mini.misc').setup()

  -- Change current working directory based on the current file path. It
  -- searches up the file tree until the first root marker ('.git' or 'Makefile')
  -- and sets their parent directory as a current directory.
  -- This is helpful when simultaneously dealing with files from several projects.
  -- MiniMisc.setup_auto_root()

  -- Restore latest cursor position on file open
  MiniMisc.setup_restore_cursor()

  -- Synchronize terminal emulator background with Neovim's background to remove
  -- possibly different color padding around Neovim instance
  MiniMisc.setup_termbg_sync()
end)

-- Notifications provider. Shows all kinds of notifications in the upper right
-- corner (by default).
now(function()
  require('mini.notify').setup()
end)

-- Session management. A thin wrapper around `:h mksession` that consistently
-- manages session files.
local autoread, autowrite = false, false
if conf_ver == 'notes' then
  -- autoread = true
  autowrite = true
end
now(function()
  require('mini.sessions').setup({
    autowrite = autowrite,
    autoread = autoread,
    directory = '~/.local/share/nvim/session', --<"session" subdir of user data directory from |stdpath()|>,
    file = 'session.vim',
    force = { read = false, write = true, delete = false },
    verbose = { read = false, write = true, delete = true },
  })
end)

-- Start screen.
if conf_ver ~= 'notes' then
  now(function()
    local ministarter = require('mini.starter')
    ministarter.setup({
      evaluate_single = true,
      items = {
        ministarter.sections.sessions(6, false),
        ministarter.sections.recent_files(3, false),
        ministarter.sections.builtin_actions(),
      },
      content_hooks = {
        ministarter.gen_hook.adding_bullet(),
        ministarter.gen_hook.indexing(),
        ministarter.gen_hook.aligning('center', 'center'),
      },
    })
  end)
end

-- Statusline.
now(function()
  -- The following code is an attempt to get lsp and formatter to display in the status line.
  -- It comes from this comment https://www.reddit.com/r/neovim/comments/xtynan/comment/iqtcq0s/?utm_source=share&utm_medium=web2x&context=3
  Lsp =
    function()
      local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
      -- local supported_formatters = require("null-ls.sources").get_available(vim.bo.filetype)
      local clients = {}

      for _, client in pairs(buf_clients) do
        if client.name ~= 'null-ls' then
          table.insert(clients, client.name)
        end
      end

      -- for _, client in pairs(supported_formatters) do
      --   table.insert(clients, client.name)
      -- end

      if #clients > 0 then
        return table.concat(clients, ', ')
      else
        return 'no LS'
      end
    end, require('mini.statusline').setup({
      content = {
        active = function()
          local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 120 })
          local git = MiniStatusline.section_git({ trunc_width = 75 })
          local diagnostics = MiniStatusline.section_diagnostics({ trunc_width = 75 })
          local filename = MiniStatusline.section_filename({ trunc_width = 140 })
          local fileinfo = MiniStatusline.section_fileinfo({ trunc_width = 120 })
          local location = MiniStatusline.section_location({ trunc_width = 75 })
          local lsp = Lsp()
          -- local noice_mode = require('noice').api.status.mode.get_hl()

          return MiniStatusline.combine_groups({
            { hl = mode_hl, strings = { mode } },
            { hl = 'MiniStatuslineDevinfo', strings = { git, diagnostics } },
            '%<', -- Mark general truncate point
            { hl = 'MiniStatuslineFilename', strings = { filename } },
            '%=', -- End left alignment
            -- { hl = 'MiniStatuslineFileinfo', strings = { noice_cmd, noice_mode } },
            -- { hl = 'MiniStatuslineFileinfo', strings = { noice_mode } },
            { hl = 'MiniStatuslineFilename', strings = { lsp } },
            { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
            { hl = mode_hl, strings = { location } },
          })
        end,
      },
    })
end)

-- Tabline.
now(function()
  require('mini.tabline').setup()
end)

-- Step two ===================================================================

-- Extra 'mini.nvim' functionality.
later(function()
  require('mini.extra').setup()
end)

-- Extend and create a/i textobjects.
later(function()
  local ai = require('mini.ai')
  ai.setup({
    -- 'mini.ai' can be extended with custom textobjects
    custom_textobjects = {
      -- Make `aB` / `iB` act on around/inside whole *b*uffer
      B = MiniExtra.gen_ai_spec.buffer(),
      F = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }),
      d = { '%f[%d]%d+' }, -- digits

      -- custom textobject for selecting markdown blocks of code
      m = function(ai_type)
        local cur_line = vim.fn.line('.')
        local lines = vim.fn.getline(1, vim.fn.line('$'))
        local start_line, end_line

        -- Search upwards for start ```
        for i = cur_line, 1, -1 do
          if lines[i]:match('^```') then
            start_line = i
            break
          end
        end

        -- Search downwards for end ```
        for i = cur_line + 1, #lines do
          if lines[i]:match('^```%s*$') then
            end_line = i
            break
          end
        end

        if ai_type == 'i' then
          end_line = end_line - 1
          start_line = start_line + 1
        end

        if start_line and end_line and end_line > start_line then
          return {
            from = { line = start_line, col = 1 },
            to = { line = end_line, col = #lines[end_line] + 1 },
          }
        end
      end,
      -- custom textobject to select the line, minus the initial bullet
      -- based on https://www.lazyvim.org/plugins/coding#miniai
      r = function(ai_type)
        local line_num = vim.fn.line('.')
        local line = vim.fn.getline(line_num)
        -- Ignore indentation for `i` textobject
        local line_len
        if line:match('^%s*[%-%+%*]%s') then
          line_len = line:match('^%s*[%-%+%*]?%s?'):len() + 1
        elseif line:match('^%s*%d+%.%s') then
          line_len = line:match('^%s*%d+%.%s'):len() + 1
        else
          line_len = line:match('^%s*'):len() + 1
        end
        local from_col = ai_type == 'a' and 1 or line_len
        -- -- previous version: this works, except matches lines that start with two --s for example
        -- local from_col = ai_type == "a" and 1 or (line:match("^%s*[%-%+%*]?%s?"):len() + 1)
        -- Don't select `\n` past the line to operate within a line
        local to_col = line:len()
        return { from = { line = line_num, col = from_col }, to = { line = line_num, col = to_col } }
      end,
    },
  })
end)

-- Align text interactively.
later(function()
  require('mini.align').setup()
end)

-- Animate common Neovim actions. Like cursor movement, scroll, window resize,
-- window open, window close. Animations are done based on Neovim events and
-- don't require custom mappings.
later(function()
  require('mini.animate').setup({
    scroll = {
      enable = false,
    },
  })
end)

-- Go forward/backward with square brackets. Implements consistent sets of mappings
-- for selected targets (like buffers, diagnostic, quickfix list entries, etc.).
later(function()
  require('mini.bracketed').setup({
    treesitter = { suffix = 'r', options = {} },
  })
end)

-- Remove buffers. Opened files occupy space in tabline and buffer picker.
-- When not needed, they can be removed.
later(function()
  require('mini.bufremove').setup()
end)

-- Show next key clues in a bottom right window. Requires explicit opt-in for
-- keys that act as clue trigger.
later(function()
  local miniclue = require('mini.clue')
  -- stylua: ignore
  miniclue.setup({
    -- Define which clues to show. By default shows only clues for custom mappings
    -- (uses `desc` field from the mapping; takes precedence over custom clue).
    clues = {
      -- This is defined in 'plugin/20_keymaps.lua' with Leader group descriptions
      Config.leader_group_clues,
      miniclue.gen_clues.builtin_completion(),
      miniclue.gen_clues.g(),
      miniclue.gen_clues.marks(),
      miniclue.gen_clues.registers(),
      miniclue.gen_clues.square_brackets(),
      -- This creates a submode for window resize mappings. Try the following:
      -- - Press `<C-w>s` to make a window split.
      -- - Press `<C-w>+` to increase height. Clue window still shows clues as if
      --   `<C-w>` is pressed again. Keep pressing just `+` to increase height.
      --   Try pressing `-` to decrease height.
      -- - Stop submode either by `<Esc>` or by any key that is not in submode.
      miniclue.gen_clues.windows({ submode_resize = true }),
      miniclue.gen_clues.z(),
      -- submodes for buffer navigation
      { mode = 'n', keys = ']b', postkeys = ']' },
      { mode = 'n', keys = '[b', postkeys = '[' },
      -- submodes for finding TODO notes
      { mode = 'n', keys = '[t', postkeys = '[' },
      { mode = 'n', keys = '[T', postkeys = '[' },
      { mode = 'n', keys = ']t', postkeys = ']' },
      { mode = 'n', keys = ']T', postkeys = ']' },
    },
    -- Explicitly opt-in for set of common keys to trigger clue window
    triggers = {
      { mode = { 'n', 'x' }, keys = '<Leader>' }, -- Leader triggers
      { mode = { 'n', 'x' }, keys = '<localleader>' }, -- Leader triggers
      { mode = 'n', keys = '\\' },                -- mini.basics
      { mode = { 'n', 'x' }, keys = '[' },        -- mini.bracketed
      { mode = { 'n', 'x' }, keys = ']' },
      { mode = 'i', keys = '<C-x>' },             -- Built-in completion
      { mode = { 'n', 'x' }, keys = 'g' },        -- `g` key
      { mode = { 'n', 'x' }, keys = "'" },        -- Marks
      { mode = { 'n', 'x' }, keys = '`' },
      { mode = { 'n', 'x' }, keys = '"' },        -- Registers
      { mode = { 'i', 'c' }, keys = '<C-r>' },
      { mode = 'n', keys = '<C-w>' },             -- Window commands
      { mode = { 'n', 'x' }, keys = 's' },        -- `s` key
      { mode = { 'n', 'x' }, keys = 'z' },        -- `z` key
    },
    window = {
      -- Show window immediately
      delay = 250,
      config = {
        -- Compute window width automatically
        width = 'auto',
        -- Use double-line border
        border = 'double',
      },
    },
  })
end)

-- Command line tweaks. Improves command line editing with:
-- - Autocompletion. Basically an automated `:h cmdline-completion`.
-- - Autocorrection of words as-you-type. Like `:W`->`:w`, `:lau`->`:lua`, etc.
-- - Autopeek command range (like line number at the start) as-you-type.
later(function()
  require('mini.cmdline').setup()
end)

-- Comment lines. Provides functionality to work with commented lines.
-- Uses `:h 'commentstring'` option to infer comment structure.
-- Example usage:
-- - `gcip` - toggle comment (`gc`) *i*inside *p*aragraph
-- - `vapgc` - *v*isually select *a*round *p*aragraph and toggle comment (`gc`)
-- - `gcgc` - uncomment (`gc`, operator) comment block at cursor (`gc`, textobject)
--
-- The built-in `:h commenting` is based on 'mini.comment'. Yet this module is
-- still enabled as it provides more customization opportunities.
later(function()
  require('mini.comment').setup({
    mappings = {
      textobject = 'ic',
    },
  })
end)

if conf_ver ~= 'notes' then
  -- Completion and signature help. Implements async "two stage" autocompletion:
  -- - Based on attached LSP servers that support completion.
  -- - Fallback (based on built-in keyword completion) if there is no LSP candidates.
  later(function()
    -- Customize post-processing of LSP responses for a better user experience.
    -- Don't show 'Text' suggestions (usually noisy) and show snippets last.
    local process_items_opts = { kind_priority = { Text = -1, Snippet = 99 } }
    local process_items = function(items, base)
      return MiniCompletion.default_process_items(items, base, process_items_opts)
    end
    require('mini.completion').setup({
      lsp_completion = {
        source_func = 'omnifunc',
        auto_setup = false,
        process_items = process_items,
      },
      window = {
        info = { border = 'single' },
        signature = { border = 'single' },
      },
    })

    -- Set 'omnifunc' for LSP completion only when needed.
    local on_attach = function(ev)
      vim.bo[ev.buf].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'
    end
    _G.Config.new_autocmd('LspAttach', nil, on_attach, "Set 'omnifunc'")

    -- Advertise to servers that Neovim now supports certain set of completion and
    -- signature features through 'mini.completion'.
    vim.lsp.config('*', { capabilities = MiniCompletion.get_lsp_capabilities() })
  end)
end

-- Autohighlight word under cursor with a customizable delay.
-- Word boundaries are defined based on `:h 'iskeyword'` option.
later(function()
  _G.cursorword_blocklist = function()
    local curword = vim.fn.expand('<cword>')
    local filetype = vim.bo.filetype

    -- Add any disabling global or filetype-specific logic here
    local blocklist = {}
    if filetype == 'lua' then
      blocklist = { 'local', 'require', '--' }
    elseif filetype == 'javascript' then
      blocklist = { 'import' }
    end

    vim.b.minicursorword_disable = vim.tbl_contains(blocklist, curword)
  end
  vim.cmd('au CursorMoved * lua _G.cursorword_blocklist()')
  require('mini.cursorword').setup()
end)

-- Work with diff hunks that represent the difference between the buffer text and
-- some reference text set by a source. Default source uses text from Git index.
-- Also provides summary info used in developer section of 'mini.statusline'.
later(function()
  require('mini.diff').setup({
    mappings = {
      apply = 'gt',
      reset = 'gT',
      textobject = 'gx',
    },
    view = {
      style = 'sign',
      -- signs = { add = '+', change = '~', delete = '-' },
    },
  })
end)

-- Navigate and manipulate file system
later(function()
  -- Enable directory/file preview
  require('mini.files').setup({
    mappings = {
      go_in = 'L',
      go_in_plus = 'l',
    },
    windows = { preview = true },
  })

  -- Add common bookmarks for every explorer. Example usage inside explorer:
  -- - `'c` to navigate into your config directory
  -- - `g?` to see available bookmarks
  local add_marks = function()
    MiniFiles.set_bookmark('c', vim.fn.stdpath('config'), { desc = 'Config' })
    local minideps_plugins = vim.fn.stdpath('data') .. '/site/pack/deps/opt'
    MiniFiles.set_bookmark('p', minideps_plugins, { desc = 'Plugins' })
    MiniFiles.set_bookmark('w', vim.fn.getcwd, { desc = 'Working directory' })
  end

  -- Keep miniFiles centered.
  -- From https://github.com/nvim-mini/mini.nvim/discussions/2173
  -- Window width based on the offset from the center, i.e. center window
  -- is 60, then next over is 20, then the rest are 10.
  -- Can use more resolution if you want like { 60, 20, 20, 10, 5 }
  local widths = { 60, 20, 20, 10, 5 }

  local ensure_center_layout = function(ev)
    local state = MiniFiles.get_explorer_state()
    if state == nil then
      return
    end

    -- Compute "depth offset" - how many windows are between this and focused
    local path_this = vim.api.nvim_buf_get_name(ev.data.buf_id):match('^minifiles://%d+/(.*)$')
    local depth_this
    for i, path in ipairs(state.branch) do
      if path == path_this then
        depth_this = i
      end
    end
    if depth_this == nil then
      return
    end
    local depth_offset = depth_this - state.depth_focus

    -- Adjust config of this event's window
    local i = math.abs(depth_offset) + 1
    local win_config = vim.api.nvim_win_get_config(ev.data.win_id)
    win_config.width = i <= #widths and widths[i] or widths[#widths]

    win_config.zindex = 99
    win_config.col = math.floor(0.5 * (vim.o.columns - widths[1]))
    local sign = depth_offset == 0 and 0 or (depth_offset > 0 and 1 or -1)
    for j = 1, math.abs(depth_offset) do
      -- widths[j+1] for the negative case because we don't want to add the center window's width
      local prev_win_width = (sign == -1 and widths[j + 1]) or widths[j] or widths[#widths]
      -- Add an extra +2 each step to account for the border width
      local new_col = win_config.col + sign * (prev_win_width + 2)
      if (new_col < 0) or (new_col + win_config.width > vim.o.columns) then
        win_config.zindex = win_config.zindex - 1
        break
      end
      win_config.col = new_col
    end

    win_config.height = depth_offset == 0 and 24 or 20
    win_config.row = math.floor(0.5 * (vim.o.lines - win_config.height))
    -- win_config.border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" }
    win_config.footer = { { tostring(depth_offset), 'Normal' } }
    vim.api.nvim_win_set_config(ev.data.win_id, win_config)
  end

  -- Keymap to set focused directory as current working directory
  local set_cwd = function()
    local path = (MiniFiles.get_fs_entry() or {}).path
    if path == nil then
      return vim.notify('Cursor is not on valid entry')
    end
    vim.fn.chdir(vim.fs.dirname(path))
  end

  -- Keymap to yank in register full path of entry under cursor
  local yank_path = function()
    local path = (MiniFiles.get_fs_entry() or {}).path
    if path == nil then
      return vim.notify('Cursor is not on valid entry')
    end
    vim.fn.setreg(vim.v.register, path)
  end

  -- Keymap to open path with system default handler (useful for non-text files)
  local ui_open = function()
    vim.ui.open(MiniFiles.get_fs_entry().path)
  end

  _G.Config.new_autocmd('User', 'MiniFilesExplorerOpen', add_marks, 'Add bookmarks')
  _G.Config.new_autocmd('User', 'MiniFilesBufferCreate', function(args)
    local b = args.data.buf_id
    vim.keymap.set('n', 'g~', set_cwd, { buffer = b, desc = 'Set cwd' })
    vim.keymap.set('n', 'gX', ui_open, { buffer = b, desc = 'OS open' })
    vim.keymap.set('n', 'gy', yank_path, { buffer = b, desc = 'Yank path' })
  end, 'Add keymaps bookmarks')
  _G.Config.new_autocmd('User', 'MiniFilesWindowUpdate', ensure_center_layout, 'Show MiniFiles centered on screen')
end)

-- Git integration for more straightforward Git actions based on Neovim's state.
later(function()
  require('mini.git').setup({
    command = {
      split = 'vertical',
    },
  })
end)

-- Highlight patterns in text. Like `TODO`/`NOTE` or color hex codes.
later(function()
  local hipatterns = require('mini.hipatterns')
  local hi_words = MiniExtra.gen_highlighter.words
  hipatterns.setup({
    highlighters = {
      -- Highlight a fixed set of common words. Will be highlighted in any place,
      -- not like "only in comments".
      -- fixme = hi_words({ 'FIXME', 'Fixme', 'fixme' }, 'MiniHipatternsFixme'),
      -- hack = hi_words({ 'HACK', 'Hack', 'hack' }, 'MiniHipatternsHack'),
      -- todo = hi_words({ 'TODO', 'Todo', 'todo' }, 'MiniHipatternsTodo'),
      -- note = hi_words({ 'NOTE', 'Note', 'note' }, 'MiniHipatternsNote'),
      -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
      fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
      hack = { pattern = '%f[%w]()HACK()%f[%W]', group = 'MiniHipatternsHack' },
      todo = { pattern = '%f[%w]()TODO()%f[%W]', group = 'MiniHipatternsTodo' },
      note = { pattern = '%f[%w]()NOTE()%f[%W]', group = 'MiniHipatternsNote' },
      question = { pattern = '%f[%w]()QUESTION()%f[%W]', group = 'MiniHipatternsNote' },

      -- Highlight hex color string (#aabbcc) with that color as a background
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })
end)

-- Visualize and work with indent scope. It visualizes indent scope "at cursor"
-- with animated vertical line. Provides relevant motions and textobjects.
later(function()
  require('mini.indentscope').setup({
    options = {
      try_as_border = true,
    },
  })
end)

-- Jump to next/previous single character. It implements "smarter `fFtT` keys"
-- (see `:h f`) that work across multiple lines, start "jumping mode", and
-- highlight all target matches.
-- later(function() require('mini.jump').setup() end)

-- Jump within visible lines to pre-defined spots via iterative label filtering.
-- Spots are computed by a configurable spotter function.
-- later(function() require('mini.jump2d').setup() end)

-- -- Special key mappings. Provides helpers to map:
-- -- - Multi-step actions. Apply action 1 if condition is met; else apply
-- --   action 2 if condition is met; etc.
-- -- - Combos. Sequence of keys where each acts immediately plus execute extra
-- --   action if all are typed fast enough. Useful for Insert mode mappings to not
-- --   introduce delay when typing mapping keys without intention to execute action.
later(function()
  require('mini.keymap').setup()
  -- Navigate 'mini.completion' menu with `<Tab>` /  `<S-Tab>`
  MiniKeymap.map_multistep('i', '<Tab>', { 'pmenu_next' })
  MiniKeymap.map_multistep('i', '<S-Tab>', { 'pmenu_prev' })
  -- On `<CR>` try to accept current completion item, fall back to accounting
  -- for pairs from 'mini.pairs'
  MiniKeymap.map_multistep('i', '<CR>', { 'pmenu_accept', 'minipairs_cr' })
  -- On `<BS>` just try to account for pairs from 'mini.pairs'
  MiniKeymap.map_multistep('i', '<BS>', { 'minipairs_bs' })
end)

-- Move any selection in any direction.
later(function()
  require('mini.move').setup({
    mappings = {
      left = '<S-left>',
      right = '<S-right>',
      down = '<S-down>',
      up = '<S-up>',

      line_left = '<S-left>',
      line_right = '<S-right>',
      line_down = '<S-down>',
      line_up = '<S-up>',
    },
  })
end)

-- Text edit operators.
later(function()
  require('mini.operators').setup({
    exchange = { prefix = 'gk' },
  })

  -- Create mappings for swapping adjacent arguments.
  vim.keymap.set('n', '<leader>A', 'gkiagkila', { remap = true, desc = 'Swap arg left' })
  vim.keymap.set('n', '<leader>a', 'gkiagkina', { remap = true, desc = 'Swap arg right' })
end)

-- Autopairs functionality.
later(function()
  require('mini.pairs').setup({
    mappings = {
      -- ["`"] = { action = "closeopen", pair = "``", neigh_pattern = "[^%S][^%S]", register = { cr = false } },
      ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\][^%a]' },
      ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\][^%a]' },
      ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\][^%a]' },
      [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
      [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
      ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },
      ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
      ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '[^%a\\].', register = { cr = false } },
      ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\].', register = { cr = false } },
    },
    modes = { command = true },
  })
end)

-- Pick anything.
later(function()
  -- Centered on screen
  local win_config = function()
    local height = math.floor(0.8 * vim.o.lines)
    local width = math.floor(0.9 * vim.o.columns)
    return {
      anchor = 'NW',
      height = height,
      width = width,
      row = math.floor(0.5 * (vim.o.lines - height)),
      col = math.floor(0.5 * (vim.o.columns - width)),
    }
  end
  require('mini.pick').setup({ window = {
    config = win_config,
    prompt_caret = '|',
  } })
  -- Adding custom picker to pick `register` entries
  MiniPick.registry.registry = function()
    local items = vim.tbl_keys(MiniPick.registry)
    table.sort(items)
    local source = { items = items, name = 'Registry', choose = function() end }
    local chosen_picker_name = MiniPick.start({ source = source })
    if chosen_picker_name == nil then
      return
    end
    return MiniPick.registry[chosen_picker_name]()
  end

  -- TODO picker, from https://github.com/nvim-mini/mini.nvim/discussions/1427
  -- this version copied from https://github.com/diego-velez/nvim/blob/62ba256eee8be84f0a4b2c48e1b534c9f8e608d3/lua/plugins/mini_pick.lua#L188
  local ns_digit_prefix = vim.api.nvim_create_namespace('cur-buf-pick-show')
  local show_todo = function(buf_id, entries, query, opts)
    MiniPick.default_show(buf_id, entries, query, opts)

    -- Add highlighting to every line in the buffer
    for line, entry in ipairs(entries) do
      for _, hl in ipairs(entry.hl) do
        local start = { line - 1, hl[1][1] }
        local finish = { line - 1, hl[1][2] }
        vim.hl.range(buf_id, ns_digit_prefix, hl[2], start, finish, { priority = vim.hl.priorities.user + 1 })
      end
    end
  end

  MiniPick.registry.todo = function()
    require('todo-comments.search').search(function(results)
      -- Don't do anything if there are no todos in the project
      if #results == 0 then
        return
      end

      local Config = require('todo-comments.config')
      local Highlight = require('todo-comments.highlight')

      for i, entry in ipairs(results) do
        -- By default, mini.pick uses the path item when an item is choosen to open it
        entry.path = entry.filename
        entry.filename = nil

        local relative_path = string.gsub(entry.path, vim.fn.getcwd() .. '/', '')
        -- Hideous HACK to cover the fact that my notes folder has a hyphen in the title
        local relative_path = string.gsub(
          relative_path,
          '/Users/hughearp/Library/CloudStorage/OneDrive%-NorwegianRefugeeCouncil/notes/',
          ''
        )
        local display = string.format('%s:%s:%s ', relative_path, entry.lnum, entry.col)
        local text = entry.text
        local start, finish, kw = Highlight.match(text)

        entry.hl = {}

        if start then
          kw = Config.keywords[kw] or kw
          local icon = Config.options.keywords[kw].icon or ' '
          -- display = icon .. display
          table.insert(entry.hl, { { 0, #icon }, 'TodoFg' .. kw })
          text = vim.trim(text:sub(start))

          table.insert(entry.hl, {
            { start + 7, #text + 4 },
            'TodoFg' .. kw,
          })
          -- table.insert(entry.hl, {
          --   { #text + 5, #text + 7 },
          --   'TodoBg' .. kw,
          -- })
          entry.text = icon .. ' ' .. text .. ' -> ' .. display
        end

        results[i] = entry
      end

      MiniPick.start({ source = { name = 'Find todo', show = show_todo, items = results } })
    end)
  end
end)

-- Manage and expand snippets.
-- How to manage snippets:
-- - 'mini.snippets' itself doesn't come with preconfigured snippets. Instead there
--   is a flexible system of how snippets are prepared before expanding.
--   They can come from pre-defined path on disk, 'snippets/' directories inside
--   config or plugins, defined inside `setup()` call directly.
-- - This config, however, does come with snippet configuration:
--     - 'snippets/global.json' is a file with global snippets that will be
--       available in any buffer
--     - 'after/snippets/lua.json' defines personal snippets for Lua language
--     - 'friendly-snippets' plugin configured in 'plugin/40_plugins.lua' provides
--       a collection of language snippets
--
-- How to expand a snippet in Insert mode:
-- - If you know snippet's prefix, type it as a word and press `<C-j>`. Snippet's
--   body should be inserted instead of the prefix.
-- - If you don't remember snippet's prefix, type only part of it (or none at all)
--   and press `<C-j>`. It should show picker with all snippets that have prefixes
--   matching typed characters (or all snippets if none was typed).
--   Choose one and its body should be inserted instead of previously typed text.
--
-- How to navigate during snippet session:
-- - Snippets can contain tabstops - places for user to interactively adjust text.
--   Each tabstop is highlighted depending on session progression - whether tabstop
--   is current, was or was not visited. If tabstop doesn't yet have text, it is
--   visualized with special "ghost" inline text: • and ∎ by default.
-- - Type necessary text at current tabstop and navigate to next/previous one
--   by pressing `<C-l>` / `<C-h>`.
-- - Repeat previous step until you reach special final tabstop, usually denoted
--   by ∎ symbol. If you spotted a mistake in an earlier tabstop, navigate to it
--   and return back to the final tabstop.
-- - To end a snippet session when at final tabstop, keep typing or go into
--   Normal mode. To force end snippet session, press `<C-c>`.
later(function()
  local lang_patterns = {
    -- Recognize special injected language of markdown tree-sitter parser
    markdown_inline = { 'markdown.json' },
  }

  local snippets = require('mini.snippets')
  local config_path = vim.fn.stdpath('config')

  local gen_loader = require('mini.snippets').gen_loader
  -- Compute custom lookup for variables with dynamic values
  local insert_with_lookup = function(snippet)
    local lookup = {
      TM_SELECTED_TEXT = table.concat(vim.fn.getreg('+', true, true), '\n'),
    }
    return MiniSnippets.default_insert(snippet, { lookup = lookup })
  end

  -- From :h MiniSnippets to automatically stop snippet session when reaching final tabstop
  local fin_stop = function(args)
    if args.data.tabstop_to == '0' then
      MiniSnippets.session.stop()
    end
  end
  -- local au_opts = { pattern = 'MiniSnippetsSessionJump', callback = fin_stop }
  _G.Config.new_autocmd('User', 'MiniSnippetsSessionJump', fin_stop, 'Stop snippet on reaching final tab')
  -- vim.api.nvim_create_autocmd('User', au_opts)

  snippets.setup({
    snippets = {
      -- Always load 'snippets/global.json' from config directory
      snippets.gen_loader.from_file(config_path .. '/snippets/global.json'),
      -- Load from 'snippets/' directory of plugins, like 'friendly-snippets'
      snippets.gen_loader.from_lang({ lang_patterns = lang_patterns }),
    },
    mappings = {
      expand = '<c-s>',
      jump_next = '<tab>',
      jump_prev = '<s-tab>',
    },
    expand = { insert = insert_with_lookup },
  })

  -- Enable snippets available at cursor to be shown as candidates in
  -- 'mini.completion' menu. This requires a dedicated in-process LSP server
  -- that will provide them.
  -- MiniSnippets.start_lsp_server()
end)

-- Split and join arguments (regions inside brackets between allowed separators).
later(function()
  require('mini.splitjoin').setup()
end)

-- Surround actions: add/delete/replace/find/highlight.
later(function()
  require('mini.surround').setup({
    search_method = 'cover_or_next',
  })
end)

-- Highlight and remove trailspace.
later(function()
  require('mini.trailspace').setup()
end)

-- Track and reuse file system visits.
later(function()
  require('mini.visits').setup()
end)
