-- Don't show line numbers in terminals
-- and enable ctrl + hjkl to navigate windows
local function set_terminal_keymaps()
  local opts = { buffer = 0 }
  -- vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
end
_G.Config.new_autocmd("TermOpen", "*", function(_)
  vim.cmd.setlocal("nonumber")
  set_terminal_keymaps()
end, "Set terminal keymaps")

-- Automatically trigger a reload / re-check of file status if it's changed on disk.
_G.Config.new_autocmd({ "FocusGained", "BufEnter" }, "*", function()
  vim.cmd.checktime()
end, "Update from disk")
