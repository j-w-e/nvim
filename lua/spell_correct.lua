local M = {}
local ns = vim.api.nvim_create_namespace('spell_fix_highlight')

function M.highlight_current_word()
  local bufnr = vim.api.nvim_get_current_buf()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local word = vim.fn.expand('<cword>')

  if word == '' then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  vim.highlight.range(bufnr, ns, 'IncSearch', { row - 1, col }, { row - 1, col + #word }, { inclusive = false })

  vim.defer_fn(function()
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end, 300)
end

return M
