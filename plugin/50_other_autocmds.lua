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
_G.Config.new_autocmd('TermOpen', '*', function(_)
  vim.cmd.setlocal('nonumber')
  set_terminal_keymaps()
end, 'Set terminal keymaps')

-- Automatically trigger a reload / re-check of file status if it's changed on disk.
_G.Config.new_autocmd({ 'FocusGained', 'BufEnter' }, '*', function()
  vim.cmd.checktime()
end, 'Update from disk')

-- Automatically format markdown files with nested bullet markers
-- 0 indent  -> "-"
-- 4 spaces  -> "*"
-- 8 spaces  -> "+"
-- repeats every 3 levels
-- ignores yaml frontmatter
-- TODO this comes straight from chatgpt. There should be a way to avoid the goto ?
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

_G.Config.new_autocmd('BufWritePre', '*.md', function(o)
  replace_markdown_bullets()
end, 'Update markdown bullets')
