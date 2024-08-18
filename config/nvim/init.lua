vim.opt.wrap = false
vim.opt.hlsearch = false                    -- clear highlights after a search
vim.o.wildmode = 'list:longest'             -- make cmdline tab completion similar to bash
vim.g.mapleader = ","                       -- use comma as map leader
vim.o.colorcolumn = '73,81,101,121,161'     -- visualize various common text widths: 72, 80, 100, 120, 160

-- always keep a number of lines and columns visible around the cursor
vim.opt.scrolloff = 5
vim.opt.sidescrolloff = 2

-- tabs vs spaces: go for spaces
vim.opt.expandtab = true
vim.opt.tabstop = 4                         -- tabs are 4 spaces
vim.opt.shiftwidth = 4                      -- indent is 4 spaces

-- show some important characters
vim.opt.list = true
vim.o.listchars= 'tab:▷⋅,trail:⋅,nbsp:⋅'

-- configure status line
vim.opt.statusline = ""
vim.opt.statusline:append("%f ")                            -- file name
vim.opt.statusline:append("%h%m%r%w")                       -- flags
vim.opt.statusline:append("[%{strlen(&ft)?&ft:'none'},")    -- filetype
vim.opt.statusline:append("disk:%{&fileencoding},")         -- file encoding
vim.opt.statusline:append("mem:%{&encoding},")              -- internal encoding
vim.opt.statusline:append("%{&fileformat}]")                -- file format
vim.opt.statusline:append("%=")                             -- right align
vim.opt.statusline:append("%-14.(%l,%c%V%) %<%P")           -- offset

vim.api.nvim_set_keymap('n', '<Leader>sp', 'vip:!sort<CR>', {}) -- sort paragraph with ,sp
vim.api.nvim_set_keymap('n', '<F5>', ':make<CR>', {})           -- invoke :make with F5

-- use system-wide python (needs pynvim installed; see also :checkhealth provider)
vim.g.python3_host_prog = '/run/current-system/sw/bin/python3'

-- todo mode
vim.api.nvim_create_autocmd("BufRead", {
    pattern = "todo",
    callback = function()
      vim.opt.background = "light"
    end,
})

-- beancount mode
local beancount_group = vim.api.nvim_create_augroup('beancount-group', {})
vim.api.nvim_create_autocmd("FileType", {
    pattern = "beancount",
    group = beancount_group,
    callback = function(ev)
        vim.api.nvim_set_keymap('i', '.', '.<C-O>:AlignCommodity<CR>', { noremap = true })
        vim.api.nvim_set_keymap('n', '<Leader>ba', ':AlignCommodity<CR>', {})
        vim.api.nvim_set_keymap('v', '<Leader>ba', ':AlignCommodity<CR>', {})
        vim.keymap.set('n', '<Leader>bn', function()
            local today = os.date('%Y-%m-%d * ""')
            vim.api.nvim_put({"", today}, 'l', true, false)
            vim.cmd.normal('j$')
            vim.cmd('startinsert')
        end, {})
        vim.keymap.set('n', '<Leader>bw', function()
            local tmpname = os.tmpname()
            vim.cmd(string.format("terminal beancount-add \"%s\" \"%s\"",
                vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)),
                vim.fn.fnameescape(tmpname)))
            vim.cmd('startinsert')
            vim.api.nvim_create_autocmd({"TermClose"}, {
                buffer = vim.api.nvim_get_current_buf(),
                callback = function()
                    vim.cmd("bdelete")
                    local num_lines = 0
                    for _ in io.lines(tmpname) do
                        num_lines = num_lines + 1
                    end
                    if num_lines > 0 then
                        vim.cmd(string.format("r %s", tmpname))
                        vim.cmd.normal(string.rep("j", num_lines))
                    end
                    os.remove(tmpname)
                end
            })
        end, {})
        vim.opt.foldlevel=99

        -- configure integration with beancount-language-server again to set journal_file
        local capabilities = require('cmp_nvim_lsp').default_capabilities()
        local journal_file_absolute = vim.fn.fnamemodify(ev.file, ":p")
        require("lspconfig").beancount.setup({
            capabilities = capabilities,
            init_options = {
                journal_file = journal_file_absolute
            }
        })
    end,
})

-- terminal mode
vim.api.nvim_set_keymap('t', '<Leader><ESC>', '<C-\\><C-n>', { noremap = true })

-- plugins
require("lazy").setup({
    spec = {
        {
            "sainnhe/gruvbox-material",
            lazy = false,
            priority = 1000,
            config = function()
                vim.o.background = 'dark'

                vim.cmd.colorscheme 'gruvbox-material'
            end,
        },

        {
            "robitx/gp.nvim",
            config = function()
                local conf = {
                    openai_api_key = "disabled",
                    providers = {
                        openai = {
                            disable = true,
                        },
                        anthropic = {
                            disable = false,
                            endpoint = "https://api.anthropic.com/v1/messages",
                            secret = { "cat", "/home/jan/.anthropicrc" },
                        },
                    },
                }
                local gp = require("gp")
                gp.setup(conf)
                vim.keymap.set('n', '<leader>ac', ':vsplit<CR><C-W>l:GpChatNew<CR>')
                vim.keymap.set('v', '<leader>ar', ':GpRewrite ')
                vim.keymap.set('v', '<leader>ap', ':GpChatPaste<CR>')
                vim.keymap.set('n', '<leader>at', ':GpChatToggle<CR>')
            end,
        },

        {
            "airblade/vim-gitgutter",
            config = function()
                vim.opt.updatetime = 2000   -- update more aggressively

                -- toggle with ,gg
                vim.api.nvim_set_keymap('n', '<Leader>gg', ':GitGutterToggle<CR>', {})
            end,
        },

        {
            "nvim-telescope/telescope.nvim",
            tag = "0.1.8",
            dependencies = { "nvim-lua/plenary.nvim" },
            config = function()
                local builtin = require('telescope.builtin')
                vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
                vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
                vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
                vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
            end,
        },

        {
            "neovim/nvim-lspconfig",
            config = function()
                local capabilities = require('cmp_nvim_lsp').default_capabilities()
                require("lspconfig").pyright.setup({
                    capabilities = capabilities
                })
                require("lspconfig").ruff_lsp.setup({
                    capabilities = capabilities
                })
                require("lspconfig").lua_ls.setup({
                    capabilities = capabilities,
                    settings = {
                        Lua = {
                            diagnostics = {
                                globals = { "vim" },
                            },
                        },
                    },
                })
                require("lspconfig").nixd.setup({})
                require("lspconfig").beancount.setup({
                    capabilities = capabilities
                })

                vim.keymap.set('n', '<Leader>lf', vim.lsp.buf.format, {})
            end,
        },

        {
            "hrsh7th/cmp-nvim-lsp",
        },

        {
            "hrsh7th/cmp-vsnip",
        },

        {
            "hrsh7th/vim-vsnip",
        },

        {
            "hrsh7th/cmp-path",
        },

        {
            "crispgm/cmp-beancount",
        },

        {
            "hrsh7th/nvim-cmp",
            config = function()
                local cmp = require("cmp")
                cmp.setup({
                    enabled = true,
                    snippet = {
                        expand = function(args)
                            vim.fn["vsnip#anonymous"](args.body)
                        end,
                    },
                    mapping = {
                        ["<C-n>"] = function(fallback)
                            if cmp.visible() then
                                cmp.select_next_item()
                            else
                                fallback()
                            end
                        end,
                        ["<C-p>"] = function(fallback)
                            if cmp.visible() then
                                cmp.select_prev_item()
                            else
                                fallback()
                            end
                        end,
                        ["<C-f>"] = cmp.mapping.complete({
                            config = {
                                sources = {
                                    {
                                        name = "path",
                                        option = {
                                            { trailing_slash = true }
                                        }
                                    }
                                }
                            }
                        }),
                        ["<C-e>"] = cmp.mapping.abort(),
                        ["<CR>"] = cmp.mapping.confirm({ select = false }),
                    },
                    sources = {
                        { name = "nvim_lsp" },
                    }
                })
                cmp.setup.filetype('beancount', {
                    sources = cmp.config.sources({
                        { name = "beancount" }
                    })
                })
            end,
        },

        {
            "jreybert/vimagit",
            init = function()
                vim.g.magit_default_fold_level = 2
                vim.g.magit_update_mode = "fast"
            end,
        },

        {
            "nathangrigg/vim-beancount",
        },

        {
            "iamcco/markdown-preview.nvim",
            cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
            build = "cd app && yarn install",
            init = function()
                vim.g.mkdp_filetypes = { "markdown" }
                vim.api.nvim_set_keymap('n', '<Leader>P', ':MarkdownPreviewToggle<CR>', {})
            end,
            ft = { "markdown" },
        },

        {
            "xuhdev/vim-latex-live-preview",
        },
    },
})

local tips = {
    "<CTRL-w>o to close all windows except the current one",
    ",sp sorts the current paragraph",
    ",gg to toggle git diff in the gutter (sign column)",
    ",hp and ,hs to preview and stage Git hunk",
    ",M to open magit buffer",
    "magit: S to stage/unstage file, hunk or visual selection",
    "magit: CC to enter commit message and CC again to commit",
    "magit: CA to set commit mode to amend",
    "magit: R to refresh magit buffer",
    "magit: q to close magit buffer",
    ":LLPStartPreview to open live preview for a latex file",
    ",P to preview markdown files",
    ",ff to search for files",
    ",fg to grep for a string",
    ",fb to search for a buffer",
    ",fh to search through help tags",
    ",<ESC> to exit terminal mode",
    "<CTRL-f> to complete filesystem paths",
    ",lf to request LSP formatting",
}
vim.api.nvim_echo({{tips[math.random(1, #tips)]}}, false, {})
