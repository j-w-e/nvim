if Config.conf_ver == 'notes' then
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
      vim.schedule(function()
        local notes_dir = vim.fn.expand('~/Library/CloudStorage/OneDrive-NorwegianRefugeeCouncil/notes')
        local session_name = 'notes'
        -- Ensure consistent working directory
        vim.cmd.cd(notes_dir)
        -- Only read if session exists
        local session_file = vim.fn.stdpath('data') .. '/session/' .. session_name
        if vim.fn.filereadable(session_file) == 1 then
          require('mini.sessions').read(session_name)
        end
        vim.o.title = true
        vim.o.titlestring = 'notes'
        vim.defer_fn(function()
          vim.cmd('filetype detect')
        end, 150)
      end)
    end,
  })
end

-- Don't show line numbers in terminals
-- and enable ctrl + hjkl to navigate windows
local function set_terminal_keymaps()
  local opts = { buffer = 0 }
  -- vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
end
Config.new_autocmd('TermOpen', '*', function(_)
  vim.cmd.setlocal('nonumber')
  set_terminal_keymaps()
end, 'Set terminal keymaps')

-- Automatically trigger a reload / re-check of file status if it's changed on disk.
Config.new_autocmd({ 'FocusGained', 'BufEnter' }, '*', function()
  vim.cmd.checktime()
end, 'Update from disk')

-- Automatically format markdown files with nested bullet markers
-- 0 indent  -> "-"
-- 4 spaces  -> "*"
-- 8 spaces  -> "+"
-- repeats every 3 levels
-- ignores yaml frontmatter
local function replace_markdown_bullets()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  local bullets = { '-', '*', '+' }
  local indent_width = vim.bo[bufnr].shiftwidth

  -- capture: indentation, bullet, space(s), content
  local pattern = '^(%s*)([%*%-%+])(%s+)(.*)$'

  local in_yaml = false

  for i, line in ipairs(lines) do
    -- Detect YAML front matter
    if i == 1 and line:match('^%-%-%-$') then
      in_yaml = true
      goto continue
    end

    if in_yaml then
      if line:match('^%-%-%-$') then
        in_yaml = false
      end
      goto continue
    end

    -- Normal markdown bullet handling
    local indent, _, space, content = line:match(pattern)
    if indent then
      local spaces = #indent
      local level = math.floor(spaces / indent_width)
      local bullet = bullets[(level % #bullets) + 1]

      lines[i] = indent .. bullet .. space .. content
    end

    ::continue::
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

Config.new_autocmd('BufWritePre', '*.md', function(o)
  replace_markdown_bullets()
end, 'Update markdown bullets')

-- Code to check updates to MiniMax config
local repo_url = 'https://github.com/nvim-mini/MiniMax.git'
local repo_name = repo_url:match('.*/(.*)%.git')
local local_repo_path = vim.fn.stdpath('data') .. '/repo_check/' .. repo_name
local state_file = local_repo_path .. '/last_commit.json'
local check_interval = 7 * 24 * 60 * 60 -- 1 week

-- Read JSON state
local function read_state()
  local f = io.open(state_file, 'r')
  if not f then
    return { last_check = 0, last_sha = nil }
  end
  local content = f:read('*a')
  f:close()
  return vim.fn.json_decode(content)
end

-- Write JSON state
local function write_state(state)
  local f = io.open(state_file, 'w')
  if f then
    f:write(vim.fn.json_encode(state))
    f:close()
  end
end

-- Clone or pull the repository
local function update_repo()
  if vim.fn.isdirectory(local_repo_path) == 0 then
    -- If repo doesn't exist, clone it
    vim.fn.system({ 'git', 'clone', repo_url, local_repo_path })
  else
    -- If repo exists, pull latest changes
    vim.fn.system({ 'git', '-C', local_repo_path, 'pull' })
  end
end

-- Get latest commit SHA from the local git repository
local function get_latest_commit(callback)
  local sha = vim.fn.system({ 'git', '-C', local_repo_path, 'rev-parse', 'HEAD' }):gsub('\n', '')
  if sha and #sha > 0 then
    callback(sha)
  end
end

-- Try to find CHANGELOG.md
local function find_changelog()
  local candidates = {
    'CHANGELOG.md',
    'Changelog.md',
    'changelog.md',
    'CHANGELOG',
  }

  for _, name in ipairs(candidates) do
    local path = local_repo_path .. '/' .. name
    if vim.fn.filereadable(path) == 1 then
      return path
    end
  end
  return nil
end

-- Prompt user to open changelog
local function prompt_changelog()
  vim.schedule(function()
    local choice = vim.fn.confirm('Repo ' .. repo_name .. ' updated. View CHANGELOG?', '&Yes\n&No', 1)

    if choice == 1 then
      local changelog = find_changelog()
      if changelog then
        vim.cmd('edit ' .. changelog)
      else
        vim.notify('No CHANGELOG file found in repo', vim.log.levels.WARN, { title = 'Repo Update' })
      end
    end
  end)
end

-- Main check function
local function check_repo()
  local state = read_state()
  local now = os.time()

  -- Only run once per interval
  if now - (state.last_check or 0) < check_interval then
    return
  end

  -- Update the repository (pull latest changes)
  update_repo()

  get_latest_commit(function(latest_sha)
    if not latest_sha then
      return
    end

    if state.last_sha and state.last_sha ~= latest_sha then
      prompt_changelog()
    end

    -- Update state
    state.last_check = now
    state.last_sha = latest_sha
    write_state(state)
  end)
end

-- Auto-run on startup (deferred so it doesn't block UI)
vim.defer_fn(function()
  check_repo()
end, 2000)
