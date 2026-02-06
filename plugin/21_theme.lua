-- Make concise helpers for installing/adding plugins in two stages
local add, later, now = MiniDeps.add, MiniDeps.later, MiniDeps.now
local now_if_args = _G.Config.now_if_args

now(function()
  add('folke/tokyonight.nvim')
  require('tokyonight').setup({
    style = 'storm',
    dim_inactive = true,
    on_highlights = function(highlights, colors)
      highlights.FlashLabel = { bg = colors.blue0, fg = colors.magenta }
      highlights.MiniTrailspace = { fg = colors.magenta }
      highlights.CursorLine = { bg = colors.fg_gutter }
      highlights.RenderMarkdownCode = { bg = colors.bg_dark1 } -- this is a lighter backgroud for code blocks. I got tired of it
    end,
  })

  local conf_ver = vim.fn.getenv('NVIM_PROFILE')
  if conf_ver == 'notes' then
    vim.cmd('colorscheme tokyonight-night')
  else
    vim.cmd('colorscheme tokyonight')
  end
end)

now(function()
  add('necrogoru/shades-of-purple.nvim')
end)
