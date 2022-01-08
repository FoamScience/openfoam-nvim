"
" This is a sample init.vim for nvim v0.6.0+
" to edit OpenFOAM cases files
"
"
" Plugins
call plug#begin('~/.local/share/nvim/plugged')
    " 0. Not strictly needed preparations
    Plug 'nvim-lua/plenary.nvim'
    Plug 'folke/tokyonight.nvim'
	Plug 'nvim-treesitter/playground'
    Plug 'karb94/neoscroll.nvim'
    Plug 'junegunn/fzf'
    Plug 'junegunn/fzf.vim' " for preview support
    Plug 'nvim-telescope/telescope.nvim'

	" 1. Tree-Sitter stuff

	" Tree-Sitter with OpenFOAM support
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
	" Text objects for TreeSitter with OpenFOAM support
	Plug 'nvim-treesitter/nvim-treesitter-textobjects'
	" Text subjects with OpenFOAM support
	Plug 'RRethy/nvim-treesitter-textsubjects'
	" Context display
	Plug 'FoamScience/nvim-treesitter-context'

	" 2. LSP stuff
	
	" Interface to the native LSP client with OpenFOAM support
    Plug 'FoamScience/nvim-lspconfig', { 'branch': 'foam' }
	" Helper plugin to install language servers
    Plug 'FoamScience/nvim-lsp-installer', { 'branch': 'foam' }
    " Auto-Complete plugins with snippets (or you can just attach to built-in omnifunc)
    Plug 'hrsh7th/nvim-cmp'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'L3MON4D3/LuaSnip'
call plug#end()

" Sane defaults
set number
set tabstop=4                                                                                                                 
set shiftwidth=4                                                                                                              
colorscheme tokyonight
let g:root_patterns=['compile_commands.json', 'Make', '.git', 'Makefile', 'package.json', 'system']


" Plugins scripting via Lua
lua <<EOF

-- Better scrolling
require('neoscroll').setup({
    -- All these keys will be mapped to their corresponding default scrolling animation
    mappings = {'<C-u>', '<C-d>', '<C-b>', '<C-f>',
                '<C-y>', '<C-e>', 'zt', 'zz', 'zb'},
})

-- Configuration for Tree-Sitter
-- Note that, for this to work, the filetype must be detected correctly
-- Which is handled automatically by nvim-treesitter plugin
local ts_config = require('nvim-treesitter.configs')
ts_config.setup {
  	-- Or you can just :TSInstall foam cpp regex
  	ensure_installed = { "foam", "cpp", "regex" },
  	sync_install = false,
  	ignore_install = {},
  	highlight = {
  	  	enable = true,
  	  	disable = {},
  	  	additional_vim_regex_highlighting = false,
  	},
}

-- Configuration for the text objects
ts_config.setup {
  	textobjects = {
  	  	select = {
  	  	  	enable = true,
  	  	  	lookahead = true,
			-- iF and aF families for selecting text objects
  	  	  	keymaps = {
  	  	  		-- v keymaps are for key-values
  	  	  	  	["av"] = "@function.outer",
  	  	  	  	["iv"] = "@function.inner",
				-- c keymaps are for dictionaries
  	  	  	  	["ac"] = "@class.outer",
  	  	  	  	["ic"] = "@class.inner",
				-- k keymaps are for comments
  	  	  	  	["ak"] = "@comment.outer",
  	  	  	  	["ik"] = "@comment.inner",
  	  	  	},
  	  	},
  	  	move = {
  	  	  	enable = true,
  	  	  	set_jumps = true,
			-- Granular control over motions on key-values and dictionaries
			-- if you want it
  	  	  	goto_next_start = {
  	  	  	  	["]m"] = "@function.outer",
  	  	  	  	["]]"] = "@class.outer",
  	  	  	},
  	  	  	goto_next_end = {
  	  	  	  	["]M"] = "@function.outer",
  	  	  	  	["]["] = "@class.outer",
  	  	  	},
  	  	  	goto_previous_start = {
  	  	  	  	["[m"] = "@function.outer",
  	  	  	  	["[["] = "@class.outer",
  	  	  	},
  	  	  	goto_previous_end = {
  	  	  	  	["[M"] = "@function.outer",
  	  	  	  	["[]"] = "@class.outer",
  	  	  	},
  	  	},
		swap = {
    	  	enable = true,
		  	-- Swap parameters; ie. if a key-value has multiple values and you want to swap them
    	  	swap_next = {
    	  	  	[",a"] = "@parameter.inner",
    	  	},
    	  	swap_previous = {
    	  	  	[",A"] = "@parameter.inner",
    	  	},
    	},
  	},
}

-- Configuration for the smart text subjects
ts_config.setup {
    textsubjects = {
        enable = true,
        keymaps = {
			-- Press v. inside a key-value or a comment (then . or ; repeatedly)
            ['.'] = 'textsubjects-smart',
			-- Press v; to select surrounding dictionary
            [';'] = 'textsubjects-container-outer',
        }
    },
}

-- Context display for long dictionaries and key-value entries
require("treesitter-context").setup({
    throttle = true,
    patterns = {
		-- This will show context for functions, classes and mehod
		-- in all languages
        default = { 'function', 'class', 'method' },
		-- In OpenFOAM files, we have dicts and key-val pairs
		-- (you might want to add '^list')
        foam = { '^dict$', '^key_value$' }
    },
    -- Make sure foam is treated with exact Lua patterns
    exact_patterns = { foam = true, }
})

-- LSP configuration

-- If you're using pure 'lspconfig' configuration
-- you'll have to put a shell `foam-ls` script on PATH:
-- node /path/to/foam-language-server/lib/foam-ls.js --stdio

--local nvim_lsp = require('lspconfig')

-- I recommend using lsp_installer instead
local lsp_installer = require("nvim-lsp-installer")

-- First things first, can't stand default error signs
local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')
  local opts = { noremap=true, silent=true }

  -- What's commented out below is NOT YET supported by the OpenFOAM language server
  -- however, you should keep them
  -- buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  -- buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  -- buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  -- buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  -- buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  -- buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
  buf_set_keymap('n', '<space>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
  buf_set_keymap('n', '<space>dd', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)
  -- These keymaps are better accessed through telescope with fuzzy searching:
  --buf_set_keymap('n', '<space>ls', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
  buf_set_keymap('n', '<space>ls', '<cmd>Telescope lsp_document_symbols<CR>', opts)
  --buf_set_keymap('n', '<space>ls', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
  buf_set_keymap('n', '<space>lS', '<cmd>Telescope lsp_workspace_symbols<CR>', opts)
  --buf_set_keymap('n', '<space>wd', '<cmd>lua vim.diagnostic.setqflist()<CR>', opts)
  buf_set_keymap('n', '<space>wd', '<cmd>Telescope diagnostics<CR>', opts)

end

-- LSP installer configuration
lsp_installer.settings({
    ui = {
        icons = {
            server_installed = "✓",
            server_pending = "➜",
            server_uninstalled = "✗"
        }
    }
})

-- Make sure these servers are installed
local servers = { 'foam' }
for _, name in pairs(servers) do
  local server_is_found, server = lsp_installer.get_server(name)
  if server_is_found then
    if not server:is_installed() then
      print("Installing " .. name)
      server:install()
    end
  end
end

-- Configure servers
-- Here, just passes the global on_attach to the server
lsp_installer.on_server_ready(function(server)
  local opts = {
    on_attach = on_attach,
  }
  server:setup(opts)
end)

-- nvim-cmp setup
local luasnip = require 'luasnip'
local cmp = require 'cmp'
cmp.setup {
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end,
    },--call ddc#custom#patch_global('sourceOptions', {'_': {'matchers': ['matcher_head'], 'sorters': ['sorter_rank']},})

    mapping = {
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
        },
        ['<Tab>'] = function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
        end,
        ['<S-Tab>'] = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
        end,
    },
    sources = {
        { name = 'nvim_lsp' },
    },
}

EOF

" AutoCmds
"augroup foam
"	au FileType foam set foldmethod=expr
"	au FileType foam set foldexpr=nvim_treesitter#foldexpr()
"augroup END
set termguicolors
