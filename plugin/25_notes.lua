-- Load blink first, as otherwise it has difficulty picking up obsidan when opening sessions

-- Make concise helpers for installing/adding plugins in two stages
local add, later, now = MiniDeps.add, MiniDeps.later, MiniDeps.now

now(function()
  add({
    source = 'saghen/blink.cmp',
    checkout = 'b19413d214068f316c78978b08264ed1c41830ec',
  })
  require('blink.cmp').setup({
    keymap = {
      preset = 'none',
      ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
      ['<C-e>'] = { 'hide', 'fallback' },
      ['<C-y>'] = { 'select_and_accept', 'fallback' },

      ['<Up>'] = { 'select_prev', 'fallback' },
      ['<Down>'] = { 'select_next', 'fallback' },
      ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
      ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },

      ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
      ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },

      -- ['<Tab>'] = { 'snippet_forward', 'fallback' },
      -- ['<S-Tab>'] = { 'snippet_backward', 'fallback' },

      ['<C-k>'] = { 'show_signature', 'hide_signature', 'fallback' },
    },
    sources = {
      providers = {
        buffer = {
          score_offset = -100,
          min_keyword_length = 4,
        },
      },
    },
  })
end)

now(function()
  add({ source = 'obsidian-nvim/obsidian.nvim', checkout = 'f513608b6a413d82cb228bba0179a36190b22d21' })
  require('obsidian').setup({
    legacy_commands = false,
    ui = { enable = false },
    checkbox = { create_new = false },
    completion = {
      nvim_cmp = false,
      blink = true,
      create_new = true,
    },
    workspaces = {
      {
        name = 'work',
        path = vim.fn.expand('~/Documents/Work/OneDrive - Norwegian Refugee Council/notes'),
      },
      {
        name = 'personal',
        path = vim.fn.expand('~/Documents/personal/notes'),
        overrides = {
          templates = {
            folder = vim.NIL,
          },
          notes_subdir = vim.NIL,
        },
      },
    },
    new_notes_location = 'notes_subdir',
    notes_subdir = 'meetings',
    search = { sort_by = 'path' },

    note_id_func = function(title)
      -- Create note IDs in a Zettelkasten format with a timestamp and a suffix.
      -- In this case a note with the title 'My new note' will be given an ID that looks
      -- like '1657296016-my-new-note', and therefore the file name '1657296016-my-new-note.md'
      local suffix = ''
      if title ~= nil then
        -- If title is given, transform it into valid file name.
        suffix = title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
      else
        -- If title is nil, just add 4 random uppercase letters to the suffix.
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
      end
      return tostring(os.date('%y%m%d')) .. '-' .. suffix
    end,

    frontmatter = {
      enable = true,
      func = function(note)
        -- Add the title of the note as an alias.
        if note.title then
          note:add_alias(note.title)
        end

        local out = { id = note.id, aliases = note.aliases, tags = note.tags, area = '' }

        -- `note.metadata` contains any manually added fields in the frontmatter.
        -- So here we just make sure those fields are kept in the frontmatter.
        if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
          for k, v in pairs(note.metadata) do
            out[k] = v
          end
        end

        return out
      end,
    },

    templates = {
      folder = 'templates',
      date_format = '%Y-%m-%d-%a',
      time_format = '%H:%M',
    },
    follow_url_func = function(url)
      -- Open the URL in the default web browser.
      vim.fn.jobstart({ 'open', url }) -- Mac OS
      -- vim.fn.jobstart({"xdg-open", url})  -- linux
      -- vim.cmd(':silent exec "!start ' .. url .. '"') -- Windows
      -- vim.ui.open(url) -- need Neovim 0.10.0+
    end,
  })
end)
