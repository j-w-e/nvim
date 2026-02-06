-- General mappings ===========================================================

local nmap = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = desc })
end

-- Paste linewise before/after current line
-- Usage: `yiw` to yank a word and `]p` to put it on the next line.
nmap('[p', '<Cmd>exe "put! " . v:register<CR>', 'Paste Above')
nmap(']p', '<Cmd>exe "put "  . v:register<CR>', 'Paste Below')

nmap('<c-n>', '<cmd>bnext<cr>', 'Next buffer')
nmap('<c-p>', '<cmd>bprev<cr>', 'Prev buffer')

-- Flash keymaps
vim.keymap.set({ 'n', 'x', 'o' }, '-', function()
  require('flash').jump()
end, { desc = 'Flash jump' })
vim.keymap.set('o', 'r', function()
  require('flash').remote()
end, { desc = 'Flash remote' })

-- stylua: ignore start

-- Leader mappings ============================================================

_G.Config.leader_group_clues = {
  { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
  { mode = 'n', keys = '<Leader>e', desc = '+Explore/Edit' },
  { mode = 'n', keys = '<Leader>f', desc = '+Find/Files' },
  { mode = 'n', keys = '<Leader>g', desc = '+Git' },
  { mode = 'n', keys = '<Leader>l', desc = '+Language' },
  { mode = 'n', keys = '<Leader>m', desc = '+Marks/Misc' },
  { mode = 'n', keys = '<Leader>o', desc = '+Other' },
  { mode = 'n', keys = '<Leader>s', desc = '+Session' },
  { mode = 'n', keys = '<Leader>t', desc = '+Terminal' },
  { mode = 'n', keys = '<Leader>v', desc = '+Visits/Vim' },

  { mode = 'x', keys = '<Leader>g', desc = '+Git' },
  { mode = 'x', keys = '<Leader>l', desc = '+Language' },
}

local nmap_leader = function(suffix, rhs, desc)
  vim.keymap.set('n', '<Leader>' .. suffix, rhs, { desc = desc })
end
local xmap_leader = function(suffix, rhs, desc)
  vim.keymap.set('x', '<Leader>' .. suffix, rhs, { desc = desc })
end

-- b is for 'Buffer'.
local new_scratch_buffer = function()
  vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, true))
end

nmap_leader('ba', '<Cmd>b#<CR>',                                 'Alternate')
nmap_leader('bd', '<Cmd>lua MiniBufremove.delete()<CR>',         'Delete')
nmap_leader('bD', '<Cmd>lua MiniBufremove.delete(0, true)<CR>',  'Delete!')
nmap_leader('bs', new_scratch_buffer,                            'Scratch')
nmap_leader('bw', '<Cmd>lua MiniBufremove.wipeout()<CR>',        'Wipeout')
nmap_leader('bW', '<Cmd>lua MiniBufremove.wipeout(0, true)<CR>', 'Wipeout!')

-- c is for 'Code' or 'Commands'
nmap_leader('c.', '@:', 'Repeat last cmd')

-- e is for 'Explore' and 'Edit'. Common usage:
-- - `<Leader>ed` - open explorer at current working directory
-- - `<Leader>ef` - open directory of current file (needs to be present on disk)
-- - `<Leader>ei` - edit 'init.lua'
-- - All mappings that use `edit_plugin_file` - edit 'plugin/' config files
local edit_plugin_file = function(filename)
  return string.format('<Cmd>edit %s/plugin/%s<CR>', vim.fn.stdpath('config'), filename)
end
local explore_at_file = '<Cmd>lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>'
local explore_quickfix = function()
  for _, win_id in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.fn.getwininfo(win_id)[1].quickfix == 1 then return vim.cmd('cclose') end
  end
  vim.cmd('copen')
end

nmap_leader('ed', '<Cmd>lua MiniFiles.open()<CR>',          'Directory')
nmap_leader('ef', explore_at_file,                          'File directory')
nmap_leader('ei', '<Cmd>edit $MYVIMRC<CR>',                 'init.lua')
nmap_leader('ek', edit_plugin_file('20_keymaps.lua'),       'Keymaps config')
nmap_leader('em', edit_plugin_file('30_mini.lua'),          'MINI config')
nmap_leader('en', '<Cmd>lua MiniNotify.show_history()<CR>', 'Notifications')
nmap_leader('eo', edit_plugin_file('10_options.lua'),       'Options config')
nmap_leader('ep', edit_plugin_file('40_plugins.lua'),       'Plugins config')
nmap_leader('eq', explore_quickfix,                         'Quickfix')

-- f is for 'Fuzzy Find'.
local pick_added_hunks_buf = '<Cmd>Pick git_hunks path="%" scope="staged"<CR>'
local pick_workspace_symbols_live = '<Cmd>Pick lsp scope="workspace_symbol_live"<CR>'
local todo_picker = '<cmd>Pick todo<cr>'
local todo_picker_cur_file = '<Cmd>lua MiniExtra.pickers.buf_lines({ scope = "current", preserve_order = true }, { source = { name = "Find todos (buf) - < c-space > to refine" } } )<CR>TODO'

nmap_leader('f/', '<Cmd>Pick history scope="/"<CR>',            '"/" history')
nmap_leader('f:', '<Cmd>Pick history scope=":"<CR>',            '":" history')
nmap_leader('fa', '<Cmd>Pick git_hunks scope="staged"<CR>',     'Added hunks (all)')
nmap_leader('fA', pick_added_hunks_buf,                         'Added hunks (buf)')
nmap_leader('fb', '<Cmd>Pick buffers<CR>',                      'Buffers')
nmap_leader('fc', '<Cmd>Pick git_commits<CR>',                  'Commits (all)')
nmap_leader('fC', '<Cmd>Pick git_commits path="%"<CR>',         'Commits (buf)')
nmap_leader('fd', '<Cmd>Pick diagnostic scope="all"<CR>',       'Diagnostic workspace')
nmap_leader('fD', '<Cmd>Pick diagnostic scope="current"<CR>',   'Diagnostic buffer')
nmap_leader('ff', '<Cmd>Pick files<CR>',                        'Files')
nmap_leader('fg', '<Cmd>Pick grep_live<CR>',                    'Grep live')
nmap_leader('fG', '<Cmd>Pick grep pattern="<cword>"<CR>',       'Grep current word')
nmap_leader('fh', '<Cmd>Pick help<CR>',                         'Help tags')
nmap_leader('fH', '<Cmd>Pick hl_groups<CR>',                    'Highlight groups')
nmap_leader('fl', '<Cmd>Pick buf_lines scope="all"<CR>',        'Lines (all)')
nmap_leader('fL', '<Cmd>Pick buf_lines scope="current"<CR>',    'Lines (buf)')
nmap_leader('fm', '<Cmd>Pick git_hunks<CR>',                    'Modified hunks (all)')
nmap_leader('fM', '<Cmd>Pick git_hunks path="%"<CR>',           'Modified hunks (buf)')
nmap_leader('fr', '<Cmd>Pick resume<CR>',                       'Resume')
nmap_leader('fR', '<Cmd>Pick lsp scope="references"<CR>',       'References (LSP)')
nmap_leader('fs', pick_workspace_symbols_live,                  'Symbols workspace (live)')
nmap_leader('fS', '<Cmd>Pick lsp scope="document_symbol"<CR>',  'Symbols document')
nmap_leader('ft', todo_picker,                                  'TODO picker')
nmap_leader('fT', todo_picker_cur_file,                         'TODO picker (buf)')
nmap_leader('fv', '<Cmd>Pick visit_paths cwd=""<CR>',           'Visit paths (all)')
nmap_leader('fV', '<Cmd>Pick visit_paths<CR>',                  'Visit paths (cwd)')
nmap_leader('fw', '<Cmd>w<CR>',                                 'Write file')
nmap_leader('fW', '<Cmd>wa<CR>',                                'Write all files')
nmap_leader('f<space>', '<cmd>Pick registry<cr>',               'All pickers')

-- g is for 'Git'.
local git_log_cmd = [[Git log --pretty=format:\%h\ \%as\ │\ \%s --topo-order]]
local git_log_buf_cmd = git_log_cmd .. ' --follow -- %'

nmap_leader('ga', '<Cmd>Git diff --cached<CR>',             'Added diff')
nmap_leader('gA', '<Cmd>Git diff --cached -- %<CR>',        'Added diff buffer')
nmap_leader('gc', '<Cmd>Git commit<CR>',                    'Commit')
nmap_leader('gC', '<Cmd>Git commit --amend<CR>',            'Commit amend')
nmap_leader('gd', '<Cmd>Git diff<CR>',                      'Diff')
nmap_leader('gD', '<Cmd>Git diff -- %<CR>',                 'Diff buffer')
nmap_leader('gl', '<Cmd>' .. git_log_cmd .. '<CR>',         'Log')
nmap_leader('gL', '<Cmd>' .. git_log_buf_cmd .. '<CR>',     'Log buffer')
nmap_leader('go', '<Cmd>lua MiniDiff.toggle_overlay()<CR>', 'Toggle overlay')
nmap_leader('gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>',  'Show at cursor')

xmap_leader('gs', '<Cmd>lua MiniGit.show_at_cursor()<CR>', 'Show at selection')

-- l is for 'Language'.
local formatting_cmd = '<Cmd>lua require("conform").format({lsp_fallback=true})<CR>'

nmap_leader('la', '<Cmd>lua vim.lsp.buf.code_action()<CR>',     'Actions')
nmap_leader('ld', '<Cmd>lua vim.diagnostic.open_float()<CR>',   'Diagnostic popup')
nmap_leader('lf', formatting_cmd,                               'Format')
nmap_leader('li', '<Cmd>lua vim.lsp.buf.implementation()<CR>',  'Implementation')
nmap_leader('lh', '<Cmd>lua vim.lsp.buf.hover()<CR>',           'Hover')
nmap_leader('lr', '<Cmd>lua vim.lsp.buf.rename()<CR>',          'Rename')
nmap_leader('lR', '<Cmd>lua vim.lsp.buf.references()<CR>',      'References')
nmap_leader('ls', '<Cmd>lua vim.lsp.buf.definition()<CR>',      'Source definition')
nmap_leader('lt', '<Cmd>lua vim.lsp.buf.type_definition()<CR>', 'Type definition')

xmap_leader('lf', formatting_cmd, 'Format selection')

-- m is for 'Marks' or 'Misc'
nmap_leader('m.', '@:', 'Repeat last command')
nmap_leader('md', '<cmd>lcd %:p:h<cr>', 'Local cd to file')

-- o is for 'Obsidian'.
nmap_leader('oz', '<Cmd>lua MiniMisc.zoom()<CR>',          'Zoom toggle')
nmap_leader('on', '<cmd>Obsidian new_from_template<cr>', 'New note')
nmap_leader('os', '<cmd>Obsidian search<cr>',            'Search notes')
nmap_leader('or', '<cmd>Obsidian rename<cr>',            'Rename note')
nmap_leader('ot', '<cmd>Obsidian tags<cr>',              'Search tags')
nmap_leader('ob', '<cmd>Obsidian backlinks<cr>',         'Backlinks')
nmap_leader('of', '<cmd>Obsidian quick_switch<cr>',      'Open note')
-- TODO do I have to adjust this based on my adjusted session.vim file?
nmap_leader('oW',
      function()
        MiniSessions.write 'zzz-notes-tmp'
        local session_file = '/Users/hughearp/.local/share/nvim/session/zzz-notes-tmp'
        local lines = vim.fn.readfile(session_file)
        table.insert(lines, 3, 'set title')
        table.insert(lines, 4, 'set titlestring=notes')
        vim.fn.writefile(lines, session_file)
      end,
      'Save tmp session'
    )
nmap_leader('oO', '<cmd>lua MiniSessions.read("zzz-notes-tmp")<cr>', 'Open tmp session')
nmap_leader('ow',
      function()
        vim.o.title = true
        vim.o.titlestring = 'notes'
      end,
      'Set window title')


-- s is for 'Session'. Common usage:
local session_new = 'MiniSessions.write(vim.fn.input("Session name: "))'

nmap_leader('sd', '<Cmd>lua MiniSessions.select("delete")<CR>', 'Delete')
nmap_leader('sn', '<Cmd>lua ' .. session_new .. '<CR>',         'New')
nmap_leader('sr', '<Cmd>lua MiniSessions.select("read")<CR>',   'Read')
nmap_leader('sw', '<Cmd>lua MiniSessions.write()<CR>',          'Write current')

-- t is for 'Terminal'
nmap_leader('tT', '<Cmd>horizontal term<CR>', 'Terminal (horizontal)')
nmap_leader('tt', '<Cmd>vertical term<CR>',   'Terminal (vertical)')

-- v is for 'Visits' or 'Vim'.
local make_pick_core = function(cwd, desc)
  return function()
    local sort_latest = MiniVisits.gen_sort.default({ recency_weight = 1 })
    local local_opts = { cwd = cwd, filter = 'core', sort = sort_latest }
    MiniExtra.pickers.visit_paths(local_opts, { source = { name = desc } })
  end
end

nmap_leader('vc', make_pick_core('',  'Core visits (all)'),       'Core visits (all)')
nmap_leader('vC', make_pick_core(nil, 'Core visits (cwd)'),       'Core visits (cwd)')
nmap_leader('vv', '<Cmd>lua MiniVisits.add_label("core")<CR>',    'Add "core" label')
nmap_leader('vV', '<Cmd>lua MiniVisits.remove_label("core")<CR>', 'Remove "core" label')
nmap_leader('vl', '<Cmd>lua MiniVisits.add_label()<CR>',          'Add label')
nmap_leader('vL', '<Cmd>lua MiniVisits.remove_label()<CR>',       'Remove label')

nmap_leader('vs', '<cmd>lua MiniStarter.open()<cr>', 'Show start screen')
nmap_leader('vu', MiniDeps.update, 'Deps update')

-- x is for 'eXit'
nmap_leader('x', '<cmd>q<cr>', 'Quit')
nmap_leader('X', '<cmd>qa!<cr>', 'Really quit')

-- y is for 'Yank'
nmap_leader('y', '<cmd>let @*=@"<cr>', "Copy yank to clipboard")

-- z is for screen movement
nmap_leader('zb', '<cmd>ToggleCursorBot 15<cr>', 'Keep cursor at bottom by 15')
nmap_leader('zm', '<cmd>ToggleCursorMid<cr>',    'Keep cursor in middle')
nmap_leader('zt', '<cmd>ToggleCursorTop 15<cr>', 'Keep cursor at top by 15')

-- punctuation are for common tasks
nmap_leader(',', '<cmd>lua require("FTerm").open()<cr>', 'Open float term')
nmap_leader('.', '<cmd>ZenMode<cr>',                     'Zen mode')
nmap_leader('<leader>', "<cmd>Pick buffers<cr>", 'Find buffers')
-- stylua: ignore end

-- Other context-specific keymaps
vim.keymap.set('t', '<esc>', '<c-\\><c-n><cmd>lua require("FTerm").toggle()<cr>')
vim.keymap.set('t', '<c-,>', '<c-\\><c-n><cmd>lua require("FTerm").toggle()<cr>')
vim.keymap.set('n', '<c-,>', '<cmd>lua require("FTerm").toggle()<cr>')
nmap('gx', '<cmd>Browse<cr>', 'Open')
nmap("'", '`', '')
nmap('`', "'", '')
vim.keymap.set('i', ',', ',<c-g>u')
vim.keymap.set('i', '.', '.<c-g>u')
vim.keymap.set('i', ';', ';<c-g>u')
-- Smart dd
vim.keymap.set('n', 'dd', function()
  if vim.fn.getline('.') == '' then
    return '"_dd'
  end
  return 'dd'
end, { expr = true })

-- TODO fix this
-- vim.keymap.set({ 'i', 'c' }, '<a-backspace>', '<c-w>', { desc = 'delete word' })

nmap('g,', 'g;', 'prev change')
nmap('g;', 'g,', 'next change')
vim.keymap.set('x', '<leader>p', '"_dP', { desc = 'Paste without overwriting' })

local function smart_line_start()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()

  -- 1. Detect markdown bullet or numbered list
  -- Matches:
  --   - item
  --   * item
  --   + item
  --   1. item
  --   1) item
  local bullet_start, bullet_end = line:find('^%s*([%-%*%+]%s+)')
  local number_start, number_end = line:find('^%s*(%d+[%.%)]+%s+)')

  local list_end = bullet_end or number_end

  if list_end then
    local target_col = list_end
    if col ~= target_col then
      vim.api.nvim_win_set_cursor(0, { row, target_col })
      return
    end
    -- If already at list text start, fall through
  end

  -- 2. Normal smart line start behavior
  local first_non_ws = line:find('%S')
  first_non_ws = first_non_ws and (first_non_ws - 1) or 0

  if col == first_non_ws then
    vim.api.nvim_win_set_cursor(0, { row, 0 })
  else
    vim.api.nvim_win_set_cursor(0, { row, first_non_ws })
  end
end
vim.keymap.set({ 'n', 'x' }, 'gh', smart_line_start, { desc = 'Start of line' })

-- vim.keymap.set(
--   { 'n', 'x' },
--   'gh',
--   "(col('.') == matchend(getline('.'), '^\\s*')+1 ? '0' : '^')",
--   { expr = true, desc = 'Start of line' }
-- )
vim.keymap.set({ 'n', 'x' }, 'gl', '$', { desc = 'End of line' })
vim.keymap.set({ 'n', 'x' }, 'gj', '%', { desc = 'Matching bracket' })

-- Jump to current Treesitter Node in insert mode
-- From https://www.reddit.com/r/neovim/comments/1k1k7ow/jump_to_current_treesitter_node_in_insert_mode/
vim.keymap.set('i', '<c-l>', function()
  local node = vim.treesitter.get_node({ ignore_injections = false })
  if node ~= nil then
    local row, col = node:end_()
    pcall(vim.api.nvim_win_set_cursor, 0, { row + 1, col })
  end
end, { desc = 'insjump' })

-- Use U to act as redo, or <c-r>, using MiniBracketed
nmap('U', '<c-r><cmd>lua MiniBracketed.register_undo_state()<cr>')

-- From helpfile for mini.keymap
-- Escape into Normal mode from Terminal mode
-- require('mini.keymap').map_combo('t', 'jk', '<BS><BS><C-\\><C-n>')
-- require('mini.keymap').map_combo('t', 'kj', '<BS><BS><C-\\><C-n>')

-- -- Helper functions from chatgpt to export markdown to html, so that I can copy and paste notes
-- local function pandoc_to_clipboard(input)
--   local cmd = "pandoc -f markdown -t html | pbcopy"
--   local handle = io.popen(cmd, "w")
--   if not handle then
--     vim.notify("Failed to run pandoc", vim.log.levels.ERROR)
--     return
--   end
--   handle:write(input)
--   handle:close()
--   vim.notify("Copied HTML to clipboard", vim.log.levels.INFO)
-- end
--
-- vim.keymap.set("n", "<leader>ox", function()
--   local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
--   pandoc_to_clipboard(table.concat(lines, "\n"))
-- end, { desc = "Pandoc: buffer → HTML → clipboard" })
--
-- vim.keymap.set("v", "<leader>ox", function()
--   local _, ls, cs = unpack(vim.fn.getpos("'<"))
--   local _, le, ce = unpack(vim.fn.getpos("'>"))
--
--   local lines = vim.api.nvim_buf_get_lines(0, ls - 1, le, false)
--
--   if #lines == 0 then return end
--
--   lines[1] = string.sub(lines[1], cs)
--   lines[#lines] = string.sub(lines[#lines], 1, ce)
--
--   pandoc_to_clipboard(table.concat(lines, "\n"))
-- end, { desc = "Pandoc: selection → HTML → clipboard" })
--
--

-- navigating TODO comments
vim.keymap.set('n', ']t', function()
  require('todo-comments').jump_next()
end, { desc = 'Next todo comment' })

vim.keymap.set('n', '[t', function()
  require('todo-comments').jump_prev()
end, { desc = 'Previous todo comment' })

vim.keymap.set('n', ']T', function()
  require('todo-comments').jump_prev()
end, { desc = 'Prev todo comment' })

vim.keymap.set('n', '[T', function()
  require('todo-comments').jump_next()
end, { desc = 'Next todo comment' })

-- set keymap to fix last spelling mistake. And insert an undo breakpoint right before changing spelling
local action = '<BS><BS><c-g>u<Esc>[s1z=gi'
require('mini.keymap').map_combo('i', 'kk', action)
