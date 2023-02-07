set incsearch               " find next match as we type
set nohlsearch
set nowrap
set background=dark
set modeline
set autoindent
set pastetoggle=<F9>
set clipboard+=unnamed      " make unnamed register the same as "*
set backspace=indent,eol,start " backspace over everything in insert mode
set showmatch               " show matching brackets
set wildmode=list:longest   " make cmdline tab completion similar to bash
let mapleader=","           " use comma as a map leader
set directory=~/tmp,.,/var/tmp,/tmp " prefer ~/tmp for swap files

" solarized8
colorscheme solarized8

set textwidth=0
set colorcolumn=73,81,101,121

" spell check
map <F12> :setlocal spell spelllang=en_us
set spellfile=~/doc/vim.spellfile.add

" sort paragraph
map <Leader>sp vip:!sort<CR>

" syntastic
let g:syntastic_always_populate_loc_list = 0
let g:syntastic_auto_loc_list = 0
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_enable_signs = 0

let g:syntastic_python_checkers = ['flake8', 'pep8', 'pyflakes', 'pylint', 'python']
let g:syntastic_javascript_checkers = ['standard']
let g:syntastic_html_checkers = ['validator']
let g:syntastic_go_checkers = ['golangci_lint']
let g:syntastic_go_golangci_lint_args = "--enable-all --fast --disable wsl --disable forbidigo"
let g:syntastic_sh_checkers = ['shellcheck']

" supertab
let g:SuperTabMappingForward = '<nul>'      " workaround for <c-space>
let g:SuperTabMappingBackward = '<s-nul>'   " effectively disabled
let g:SuperTabDefaultCompletionType = "<C-X><C-O>"

" jedi-vim
let g:jedi#use_splits_not_buffers = "top"

" vimagit
let g:magit_show_help=0
let g:magit_default_fold_level=2
let g:magit_default_sections = ['commit', 'staged', 'unstaged', 'info', 'global_help']

" vim-gitgutter
set updatetime=2000         " update more aggressively
map <Leader>gg :GitGutterToggle<CR>

" vimtips-fortune
let g:fortune_vimtips_file = "../../../../../vimtips/vimtips"
let g:fortune_vimtips_display_in_window = 0
let g:fortune_vimtips_display_in_tooltip = 1

" GitHub Copilot
let g:copilot_filetypes = {'*': v:false}    " off by default
" Default maps somehow interfere with 'Ü'. Map explicitly, so
" that the plugin does not create its own mapping.
imap <M-Bslash> Ü
command EnableCopilot let b:copilot_enabled=v:true

" always keep a number of lines and columns visible around the cursor
set scrolloff=5
set sidescrolloff=2
set sidescroll=1            " scroll vertically in small steps

" tabs usually cause problems; just use 4 spaces instead
set expandtab               " use spaces, not tabs.
set tabstop=4               " tabs are 4 spaces
set shiftwidth=4            " indent is 4 spaces
set smarttab                " tab goes to the next tab stop
set list
set listchars=tab:▷⋅,trail:⋅,nbsp:⋅

syntax on
filetype plugin on
filetype indent on

" set up a good status line
set laststatus=2
set statusline=
set statusline+=%f\                             " file name
set statusline+=%h%m%r%w                        " flags
set statusline+=\[%{strlen(&ft)?&ft:'none'},    " filetype
set statusline+=disk:%{&fileencoding},          " file encoding
set statusline+=mem:%{&encoding},               " internal encoding
set statusline+=%{&fileformat}]                 " file format
set statusline+=\ %{&paste?'[paste]':''}\ 
set statusline+=%=                              " right align
set statusline+=%-14.(%l,%c%V%)\ %<%P           " offset

" compile function
function! Compile()
    if filereadable("Makefile")
        set makeprg=make
    elseif match(bufname("%"), "\.hs$") != -1 
        echo "haskell file; setting compiler to ghc"
        compiler ghc
    elseif match(bufname("%"), "\.java$") != -1 
        echo "java file; trying javac on current file"
        let mkcmd = 'set makeprg=javac\ ' . bufname("%")
        execute mkcmd
    endif
    echo "building... please wait"
    silent w
    silent make
    redraw!
endfunction
map <F5> :call Compile() \| cc! <CR>

" tag list plugin
nnoremap <silent> <F8> :TlistToggle<CR>

" haskell mode
function! OpenInGHCI()
    let ghcicmd = '!x-terminal-emulator -e ghci "' . bufname("%") . '" &'
    silent execute ghcicmd
    redraw!
endfunction
function! HsSetup()
    map <F6> :call OpenInGHCI() <CR>
    let b:ghc_staticoptions="-i.. -i../.. -i../../.."
    let b:ghc_staticoptions_wall="-Wall -i.. -i../.. -i../../.."
endfunction
au FileType haskell call HsSetup()
au FileType hamster call HsSetup()
au BufEnter *.hs compiler ghc
let g:haddock_browser="google-chrome"
let g:haddock_indexfiledir=$HOME."/.vim/"

" javascript mode
function! JsSetup()
    set tabstop=2             " tabs are 2 spaces
    set shiftwidth=2          " indent is 2 spaces
endfunction
au FileType javascript call JsSetup()

" go mode
function! GoSetup()
    set nolist
    nmap <Leader>d <Plug>(go-def-split)
    nmap <Leader>e <Plug>(go-iferr)
endfunction
au FileType go call GoSetup()

" beancount mode
function! BeancountAdd()
    let l:beancount_add_file = tempname()
    silent execute '!beancount-add ' . shellescape(expand('%')) .
        \ ' ' . l:beancount_add_file
    redraw!
    let l:lines = split(system('wc ' . shellescape(l:beancount_add_file)))[0]
    silent execute 'r ' . l:beancount_add_file
    while l:lines > 1
        normal j
        let l:lines = l:lines - 1
    endwhile
    call delete(l:beancount_add_file)
endfunction

function! BeancountSetup()
    inoremap . .<C-O>:AlignCommodity<CR>
    map <Leader>a :AlignCommodity<CR>
    map <Leader>n :call BeancountAdd()<CR>
    map <Leader>N o<ESC>:put =strftime('%Y-%m-%d * \"\"')<CR>$i
    set foldlevel=99
endfunction
au FileType beancount call BeancountSetup()

" todo mode
au BufRead todo set bg=light
