vim.keymap.set('n', '<localleader>d', function()
  local absolute_image_path = '/tmp/r.png'
  local command = 'qlmanage -p ' .. vim.fn.shellescape(absolute_image_path) .. ' > /dev/null 2>&1'
  local success = os.execute(command)
  if success then
    print('Opened image in Preview: ' .. absolute_image_path)
  else
    print('Failed to open image in Preview: ' .. absolute_image_path)
  end
end, { desc = 'Show r plot' })
