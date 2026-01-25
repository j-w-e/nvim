-- Make concise helpers for installing/adding plugins in two stages
local add, later = MiniDeps.add, MiniDeps.later
local now_if_args = _G.Config.now_if_args

now_if_args(function()
  add('folke/tokyonight.nvim')
  require('tokyonight').setup({
    style = 'storm',
    dim_inactive = true,
    on_highlights = function(highlights, colors)
      highlights.FlashLabel = { bg = colors.blue0, fg = colors.magenta }
      highlights.MiniTrailspace = { fg = colors.magenta }
      highlights.CursorLine = { bg = colors.fg_gutter }
      -- highlights.RenderMarkdownCode = { bg = colors.fg_gutter }  -- this is a lighter backgroud for code blocks. I got tired of it
      highlights.RenderMarkdownCode = { bg = '#16161e' } -- this is for a dark background to code blocks
    end,
  })
  vim.cmd('colorscheme tokyonight')
end)
