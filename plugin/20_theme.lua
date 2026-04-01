-- Make concise helpers for installing/adding plugins in two stages
local add = vim.pack.add
local now, now_if_args, later = Config.now, Config.now_if_args, Config.later

now(function()
  add({ 'https://github.com/folke/tokyonight.nvim' })
  require('tokyonight').setup({
    style = 'storm',
    dim_inactive = true,
    on_highlights = function(highlights, colors)
      highlights.FlashLabel = { bg = colors.blue0, fg = colors.magenta }
      highlights.MiniTrailspace = { fg = colors.magenta }
      highlights.CursorLine = { bg = colors.fg_gutter }
      highlights.RenderMarkdownCode = { bg = colors.bg_dark1 } -- this is a lighter backgroud for code blocks. I got tired of it
      highlights.DiagnosticUnnecessary = { fg = colors.magenta }
    end,
  })

  if Config.conf_ver == 'notes' then
    vim.cmd('colorscheme tokyonight-night')
  else
    vim.cmd('colorscheme tokyonight')
  end
end)
