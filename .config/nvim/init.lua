-- ===================================================================
-- Leon Kasdorf – Neovim config (Kickstart-based, with fixes applied)
-- ===================================================================

-- Optional: hide the noisy lspconfig deprecation warning only (keep others)
local _notify = vim.notify
vim.notify = function(msg, level, opts)
  if type(msg) == "string"
     and msg:find("require%('lspconfig'%)%s*\"framework\"%s*is%s*deprecated") then
    return
  end
  _notify(msg, level, opts)
end

-- nur die lspconfig-"framework is deprecated"-Warnung ausblenden
local _notify = vim.notify
vim.notify = function(msg, level, opts)
  if type(msg) == "string" then
    local m = msg:lower()
    if m:find("lspconfig") and m:find("framework") and m:find("deprecated") then
      return
    end
  end
  _notify(msg, level, opts)
end


require('keymaps')

-- Leader keys (must be set before plugins)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable netrw (using other file explorers)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Install/boot lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Toggle Aerial with <leader>.
vim.keymap.set('n', '<leader>.', '<cmd>AerialToggle!<CR>')

-- Plugins
require('lazy').setup({
  -- Git
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- Detect tabstop/shiftwidth
  'tpope/vim-sleuth',

  -- LSP core + helpers
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',
      { 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },
      'folke/neodev.nvim',
    },
  },

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = function() vim.g.mkdp_filetypes = { "markdown" } end,
    ft = { "markdown" },
  },

  -- Completion
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'rafamadriz/friendly-snippets',
    },
  },

  -- Which-key
  { 'folke/which-key.nvim', opts = {} },

  -- Gitsigns
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' }, change = { text = '~' }, delete = { text = '_' },
        topdelete = { text = '‾' }, changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        vim.keymap.set('n', '<leader>gp', require('gitsigns').prev_hunk, { buffer = bufnr, desc = '[G]o to [P]revious Hunk' })
        vim.keymap.set('n', '<leader>gn', require('gitsigns').next_hunk, { buffer = bufnr, desc = '[G]o to [N]ext Hunk' })
        vim.keymap.set('n', '<leader>ph', require('gitsigns').preview_hunk, { buffer = bufnr, desc = '[P]review [H]unk' })
      end,
    },
  },

  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    opts = {
      options = {
        icons_enabled = false, theme = 'onedark',
        component_separators = '|', section_separators = '',
      },
    },
  },

  -- Comment toggling
  { 'numToStr/Comment.nvim', opts = {} },

  -- Telescope (+ fzf native if available)
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function() return vim.fn.executable('make') == 1 end,
      },
    },
  },

  -- Treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects' },
    build = ':TSUpdate',
  },

  -- Additional custom plugins (your own module)
  { import = 'custom.plugins' },

  -- Aerial (symbols outline)
  'stevearc/aerial.nvim',

  -- Clipboard images (markdown paste helper)
  'ekickx/clipboard-image.nvim',

  -- Theme
  'lunarvim/synthwave84.nvim',
}, {
  -- more generous git timeout for slow networks
  git = { timeout = 300 },
})

-- =========================
-- General editor settings
-- =========================
vim.o.hlsearch = true
vim.wo.number = true
vim.o.mouse = 'a'
vim.o.clipboard = 'unnamedplus'
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.wo.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.completeopt = 'menuone,noselect'
vim.o.termguicolors = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.undodir = vim.fn.expand('~/.vim/undodir')
vim.opt.undofile = true
vim.wo.relativenumber = true
vim.opt.spell = false

-- Basic keymaps
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function() vim.highlight.on_yank() end,
  group = highlight_group, pattern = '*',
})

-- Telescope config
require('telescope').setup({
  defaults = {
    mappings = { i = { ['<C-u>'] = false, ['<C-d>'] = false } },
    file_ignore_patterns = { "^./.git/", "^node_modules/", "^vendor/", "%.jpg", "%.png" },
  },
})
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'file_browser')
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Recent files' })
vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files,  { desc = '[G]it [F]iles' })
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags,  { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string,{ desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep,  { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics,{ desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>/', function()
  require('telescope.builtin').current_buffer_fuzzy_find(
    require('telescope.themes').get_dropdown({ winblend = 10, previewer = false })
  )
end, { desc = 'Fuzzy search in buffer' })

-- Treesitter
require('nvim-treesitter.configs').setup({
  ensure_installed = { 'c','cpp','go','lua','python','rust','tsx','javascript','typescript','vimdoc','vim' },
  auto_install = false,
  highlight = { enable = true },
  indent = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = '<c-space>',
      node_incremental = '<c-space>',
      scope_incremental = '<c-s>',
      node_decremental = '<M-space>',
    },
  },
  textobjects = {
    select = {
      enable = true, lookahead = true,
      keymaps = {
        ['aa'] = '@parameter.outer', ['ia'] = '@parameter.inner',
        ['af'] = '@function.outer',  ['if'] = '@function.inner',
        ['ac'] = '@class.outer',     ['ic'] = '@class.inner',
      },
    },
    move = {
      enable = true, set_jumps = true,
      goto_next_start = { [']m'] = '@function.outer', [']]'] = '@class.outer' },
      goto_next_end   = { [']M'] = '@function.outer', [']['] = '@class.outer' },
      goto_previous_start = { ['[m'] = '@function.outer', ['[['] = '@class.outer' },
      goto_previous_end   = { ['[M'] = '@function.outer', ['[]'] = '@class.outer' },
    },
  },
})

-- Diagnostics mappings
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Prev diagnostic' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Diagnostics float' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics list' })

-- =========================
-- LSP configuration
-- =========================

-- on_attach runs when an LSP connects to a buffer
local on_attach = function(_, bufnr)
  local nmap = function(keys, func, desc)
    if desc then desc = 'LSP: ' .. desc end
    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>rn', vim.lsp.buf.rename,        '[R]e[n]ame')
  nmap('<leader>ca', vim.lsp.buf.code_action,   '[C]ode [A]ction')

  nmap('gd', vim.lsp.buf.definition,            '[G]oto [D]efinition')
  nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  nmap('gI', vim.lsp.buf.implementation,        '[G]oto [I]mplementation')
  nmap('<leader>D', vim.lsp.buf.type_definition,'Type [D]efinition')
  nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
  nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

  nmap('K',    vim.lsp.buf.hover,               'Hover')
  nmap('<C-k>',vim.lsp.buf.signature_help,      'Signature')

  nmap('gD', vim.lsp.buf.declaration,           '[G]oto [D]eclaration')
  nmap('<leader>wa', vim.lsp.buf.add_workspace_folder,    '[W]orkspace [A]dd')
  nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove')
  nmap('<leader>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, '[W]orkspace [L]ist')

  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function() vim.lsp.buf.format() end,
    { desc = 'Format current buffer with LSP' })
end

-- Servers and (optional) per-server settings
local servers = {
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
    },
  },
  -- Add more servers here with 'settings' or 'filetypes' keys if needed
}

-- neodev (better Lua support for Neovim config)
require('neodev').setup()

-- CMP capabilities
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

-- Mason must be set up BEFORE using mason-lspconfig
require('mason').setup()

-- mason-lspconfig ensure list = servers + extras
local mason_lspconfig = require('mason-lspconfig')
local ensure = vim.tbl_keys(servers)
for _, extra in ipairs({ 'bashls', 'marksman', 'powershell_es', 'lua_ls', 'luau_lsp' }) do
  if not vim.tbl_contains(ensure, extra) then table.insert(ensure, extra) end
end

mason_lspconfig.setup({
  ensure_installed = ensure,
  automatic_installation = true,
})

-- one-server setup helper
local function setup_one(server_name)
  local lsp = require('lspconfig')
  local opts = { capabilities = capabilities, on_attach = on_attach }
  if servers[server_name] ~= nil then
    local s = servers[server_name]
    if s.settings  then opts.settings  = s.settings  end
    if s.filetypes then opts.filetypes = s.filetypes end
  end
  lsp[server_name].setup(opts)
end

-- Prefer setup_handlers; fallback if unavailable
if type(mason_lspconfig.setup_handlers) == 'function' then
  mason_lspconfig.setup_handlers({
    function(server_name) setup_one(server_name) end,
  })
else
  for name, _ in pairs(servers) do setup_one(name) end
  for _, extra in ipairs({ 'bashls', 'marksman', 'powershell_es', 'lua_ls', 'luau_lsp' }) do
    setup_one(extra)
  end
end

-- =========================
-- nvim-cmp completion
-- =========================
local cmp = require('cmp')
local luasnip = require('luasnip')
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup({})

cmp.setup({
  snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
  mapping = cmp.mapping.preset.insert({
    ['<C-n>']   = cmp.mapping.select_next_item(),
    ['<C-p>']   = cmp.mapping.select_prev_item(),
    ['<C-d>']   = cmp.mapping.scroll_docs(-4),
    ['<C-f>']   = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete({}),
    ['<CR>']    = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
    ['<Tab>']   = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { 'i', 's' }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
})

-- =========================
-- Extras
-- =========================

-- Clipboard image helper (for Markdown/Hugo)
require('clipboard-image').setup({
  markdown = {
    img_dir = { "%:p:h", "content", "%:t:r" },
    img_dir_txt = { "content", "%:t:r" },
    img_name = function ()
      vim.fn.inputsave()
      local name = vim.fn.input('Name: ')
      vim.fn.inputrestore()
      if name == nil or name == '' then
        return os.date('%y-%m-%d-%H-%M-%S')
      end
      return name
    end,
  }
})

-- Telescope zoxide extension (if installed)
local ok_zutils, z_utils = pcall(require, "telescope._extensions.zoxide.utils")
if ok_zutils then
  require('telescope').setup({
    extensions = {
      zoxide = {
        prompt_title = "[ Walking on the shoulders of TJ ]",
        mappings = {
          default = { after_action = function(selection)
            print("Update to (" .. selection.z_score .. ") " .. selection.path)
          end },
          ["<C-s>"] = {
            before_action = function(_) print("before C-s") end,
            action = function(selection) vim.cmd.edit(selection.path) end
          },
          ["<C-q>"] = { action = z_utils.create_basic_command("split") },
        },
      }
    }
  })
end

-- Theme
require('synthwave84').setup({
  glow = {
    error_msg = true, type2 = true, func = true, keyword = true,
    operator = false, buffer_current_target = true,
    buffer_visible_target = true, buffer_inactive_target = true,
  }
})

-- Aerial symbols outline
require('aerial').setup({
  on_attach = function(bufnr)
    vim.keymap.set('n', '{', '<cmd>AerialPrev<CR>', { buffer = bufnr })
    vim.keymap.set('n', '}', '<cmd>AerialNext<CR>', { buffer = bufnr })
  end,
})

vim.cmd([[colorscheme synthwave84]])

-- vim: ts=2 sts=2 sw=2 et

