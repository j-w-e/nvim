local M = {}

--------------------------------------------------
-- Highlight state
--------------------------------------------------
local hl_matches = {}

local function clear_highlight()
  for _, id in ipairs(hl_matches) do
    pcall(vim.fn.matchdelete, id)
  end
  hl_matches = {}
end

--------------------------------------------------
-- State
--------------------------------------------------
local last = nil

local function set_last(fn, opts)
  last = { fn = fn, opts = vim.deepcopy(opts) }
end

--------------------------------------------------
-- Repeat
--------------------------------------------------
function M.repeat_forward()
  if not last then
    return
  end
  last.fn(last.opts)
end

function M.repeat_backward()
  if not last then
    return
  end

  local opts = vim.deepcopy(last.opts)

  -- flip direction (mini.jump)
  if opts.reverse ~= nil then
    opts.reverse = not opts.reverse
  end

  -- flip direction (mini.bracketed)
  if opts.direction then
    local map = {
      forward = 'backward',
      backward = 'forward',
      first = 'last',
      last = 'first',
    }
    opts.direction = map[opts.direction] or opts.direction
  end

  last.fn(opts)
end

--------------------------------------------------
-- f/F/t/T via mini.jump
--------------------------------------------------

local function highlight_char(char)
  clear_highlight()

  local first = vim.fn.line('w0')
  local last = vim.fn.line('w$')

  for lnum = first, last do
    local line = vim.fn.getline(lnum)
    local col_start = 1

    while true do
      local s, e = string.find(line, vim.pesc(char), col_start)
      if not s then
        break
      end

      local id = vim.fn.matchaddpos('Search', {
        { lnum, s, 1 },
      })

      table.insert(hl_matches, id)
      col_start = e + 1
    end
  end

  vim.defer_fn(clear_highlight, 1000)
end

local function make_char_jump(reverse, till, record)
  return function()
    local char = vim.fn.getcharstr()
    if char == '' then
      return
    end

    highlight_char(char)

    local pattern = vim.pesc(char)

    local function do_jump(o)
      local flags = o.reverse and 'bW' or 'W'

      -- avoid re-hitting same match
      local line = vim.fn.line('.')
      local col = vim.fn.col('.')
      local new_col = col + (o.reverse and -1 or 1)
      if new_col < 1 then
        new_col = 1
      end

      vim.api.nvim_win_set_cursor(0, { line, new_col - 1 })

      local pos = vim.fn.search(o.pattern, flags)
      if pos > 0 and o.till then
        local offset = o.reverse and 1 or -1
        vim.api.nvim_win_set_cursor(0, {
          vim.fn.line('.'),
          vim.fn.col('.') + offset - 1,
        })
      end
    end

    local opts = {
      pattern = pattern,
      reverse = reverse,
      till = till,
    }

    -- ✅ Only record in normal mode
    if record then
      set_last(do_jump, opts)
    end

    do_jump(opts)
  end
end
local function make_op_char_jump(key)
  return function()
    local char = vim.fn.getcharstr()
    if char == '' then
      return ''
    end
    return key .. char
  end
end

function M.setup_jump()
  -- NORMAL MODE (your repeat system)
  vim.keymap.set('n', 'f', make_char_jump(false, false, true))
  vim.keymap.set('n', 'F', make_char_jump(true, false, true))
  vim.keymap.set('n', 't', make_char_jump(false, true, true))
  vim.keymap.set('n', 'T', make_char_jump(true, true, true))

  -- OPERATOR-PENDING MODE (delegate to Vim!)
  vim.keymap.set('o', 'f', make_op_char_jump('f'), { expr = true })
  vim.keymap.set('o', 'F', make_op_char_jump('F'), { expr = true })
  vim.keymap.set('o', 't', make_op_char_jump('t'), { expr = true })
  vim.keymap.set('o', 'T', make_op_char_jump('T'), { expr = true })
end

--------------------------------------------------
-- mini.bracketed integration
--------------------------------------------------
local function bracketed_motion(fn, direction)
  return function()
    set_last(function(opts)
      fn(opts.direction)
    end, { direction = direction })

    fn(direction)
  end
end

function M.setup_bracketed()
  local ok, bracketed = pcall(require, 'mini.bracketed')
  if not ok then
    return
  end

  local map = function(lhs, fn, dir)
    vim.keymap.set('n', lhs, bracketed_motion(fn, dir), { silent = true })
  end

  map(']b', bracketed.buffer, 'forward')
  map('[b', bracketed.buffer, 'backward')

  map(']c', bracketed.comment, 'forward')
  map('[c', bracketed.comment, 'backward')

  map(']q', bracketed.quickfix, 'forward')
  map('[q', bracketed.quickfix, 'backward')
end

--------------------------------------------------
-- TODO navigation
--------------------------------------------------
local function jump_todo(opts)
  local pattern = [[\v<(TODO|FIXME|BUG|HACK)>]]
  local flags = opts.reverse and 'bW' or 'W'
  vim.fn.search(pattern, flags)
end

function M.setup_todo()
  vim.keymap.set('n', ']t', function()
    local opts = { reverse = false }
    set_last(jump_todo, opts)
    jump_todo(opts)
  end)

  vim.keymap.set('n', '[t', function()
    local opts = { reverse = true }
    set_last(jump_todo, opts)
    jump_todo(opts)
  end)
end

--------------------------------------------------
-- Repeat keys
--------------------------------------------------
function M.setup_repeat()
  vim.keymap.set({ 'n', 'x', 'o' }, ',', M.repeat_forward, { desc = 'Repeat forward' })
  vim.keymap.set({ 'n', 'x', 'o' }, ';', M.repeat_backward, { desc = 'Repeat backward' })
end

--------------------------------------------------
-- Setup
--------------------------------------------------
function M.setup()
  require('mini.jump').setup({})
  require('mini.bracketed').setup({})

  M.setup_repeat()
  M.setup_jump()
  M.setup_bracketed()
  M.setup_todo()
end

return M
