" Map the leader key to a backslash. (Key Rebind)
let mapleader = '\'

:set modifiable                 " Enable Buffer Modifiable (ma short of modifiable)

syntax on			            " Enable syntax highlighting
filetype plugin indent on 	    " Enable file type based indentation.

set autoindent			        " Respect indentation when starting a new line.
set expandtab			        " Expand tabs to space. Essential in python.
set tabstop=4			        " Number of spaces tab is counted for.
set shiftwidth=4		        " Number of spaces to use for autoindent.

set backspace=2			        " Fix backspace behaviour on most terminals.

" set directory=$HOME/.vim/swap//  Swap files in a single directory.
" set noswapfile                   No swap files



" Set up persistence undo across all files.

" set undofile
" if !isdirectory("$HOME)/.vim/undodir")
"    call mkdir("$HOME/.vim/undodir", \"p\")
" endif
" set undodir="$HOME/.vim/undodir"

" Set up persistence undo across all files, Enable persistence undo."
" set undofile                    
" if !isdirectory("~/.vim/undodir")
"    call mkdir("~/.vim/undodir", \"p\")
" endif


packloadall                     " Load all plugins
silent! helptags ALL            " Load help files for all plugins.


" Fast split navigation with <Ctrl + w> + hjkl
noremap <c-h> <c-w><c-h>
noremap <c-j> <c-w><c-j>
noremap <c-k> <c-w><c-k>
noremap <c-l> <c-w><c-l>


" <Ctrl + w> + hjkl in Terminal mode
tnoremap <c-j> <c-w><c-j>
tnoremap <c-k> <c-w><c-k>
tnoremap <c-l> <c-w><c-l>
tnoremap <c-h> <c-w><c-h>


" This will be able to use :Bd to close 
" the buffer while keeping a split window open
command! Bd :bp | :sp | :bn | :bd   " Close buffer without closing window 


" Fold Method, This will tell vim to fold based on indentation
set foldmethod=indent


" This will keep the folds open as you open new files, This tells Vim to
" execute zR (open all folds when reading the buffer)
autocmd BufRead * normal zR      


set wildmenu                    " Enable enhanced tab autocomplete.
set wildmode=list:longest,full  " Complete till longest string, then open the wildmenu.      


" let NERDTreeShowBookmarks = 1   " Display bookmarks on startup.
" autocmd VimEnter * NERDTree     " Enable NERDTree on Vim Startup.


" Autoclose NERDTree if it's the only open window left.
autocmd bufenter * if (winnr("$") == 1 && exists ("b:NERDTree") && 
            \ b:NERDTree.isTabTree()) | q | endif


let NERDTreeHijackNetrw = 0     " Avoid NERDTree replacing Netrw Because Vinegar plugin do replace


nnoremap <C-b> :CtrlPBuffer<cr> " Map CtrlP buffer mode to Ctrl + B

":set number                     " Display Line Number 
:set relativenumber              " Display Line Relative Number 


set hlsearch                     " Highlights every match on the screen
set incsearch                    " Dynamically move to the first match as soon as you type

" Copy and Paste from the * register
" set clipboard=unnamed               " Copy into System (*) register
" set clipboard=unnamedplus           " Copy into System (+) register
" set clipboard=unnamed, unnamedplus  " Copy into System (*, +) register

" Manage plugins with vim-plug (Specify a directory for plugins)
call plug#begin()

Plug 'vim-airline/vim-airline'              " Lean & mean status/tabline for vim that's light as air.
Plug 'vim-airline/vim-airline-themes'       " vim airline themes 
Plug 'flazz/vim-colorschemes'               " One stop shop for vim colorschemes.
Plug 'vim-scripts/ScrollColors'             " ScrollColors.vim - Colorsheme Scroller, Chooser, and Browser
Plug 'NLKNguyen/papercolor-theme'           " Light & Dark color schemes for terminal and GUI Vim awesome editor, Inspired by Google's Material Design
Plug 'w0rp/ale'                             " ALE (Asynchronous Lint Engine) is a plugin providing linting (syntax checking and semantic errors) 
Plug 'vim-syntastic/syntastic'              " Syntastic is a syntax checking plugin for Vim
Plug 'janko-m/vim-test'                     " A Vim wrapper for running tests on different granularities.
Plug 'tpope/vim-dispatch'                   " Leverage the power of Vim's compiler plugins without being bound by synchronicity.
Plug 'christoomey/vim-tmux-navigator'       " Adds support for consistent navigation between Vim Windows and tmux panes 
Plug 'tpope/vim-fugitive'                   " Git intergration in vim
Plug 'sjl/gundo.vim'                        " Visualize the Undo tree
Plug 'preservim/nerdtree'
Plug 'tpope/vim-vinegar'
Plug 'ctrlpvim/ctrlp.vim'                   " fuzzy find files
Plug 'mileszs/ack.vim'
Plug 'easymotion/vim-easymotion'
Plug 'tpope/vim-unimpaired'
Plug 'junegunn/vim-plug'
let g:plug_timeout = 300                    " Increase vim-plug timeout for YouCompleteMe
Plug 'Valloric/YouCompleteMe',  {'do': './install.py'}

" Initialize plugin system
call plug#end()


" Install vim-plug if it's not already installed.
if empty (glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.github.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif


" Remapping Commands
noremap ; :     " Use ; in addition to : to type commands.


" Map arrow keys nothing so I can get used to hjkl-style movement. 
map <up> <nop>
map <down> <nop>
map <left> <nop>
map <right> <nop>


" Immediately add a closing quotes or braces in insert mode.
inoremap ' ''<esc>i
inoremap " ""<esc>i
inoremap ( ()<esc>i
inoremap { {}<esc>i
inoremap [ []<esc>i


" Save a file with leader-w.
noremap <leader>w :w<cr>


" NERDTreeToggle
noremap <leader>n :NERDTreeToggle<cr>


" Jump to function definition
noremap <leader>] :YcmCompleter GoTo<cr>


" Start Syntastic configuration

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0 

" End Syntastic configuration


" Start Asynchronous Lint Engine (ALE)

let g:ale_completion_enabled = 1                " Enable autocomplete

" End Asynchronous Lint Engine (ALE)


" Start Color Scheme and background color setting
colorscheme PaperColor		                            " Change a colorscheme.  
set background=dark
" End Color Scheme and background color setting


" Start Status Line 

" Always display a status line (It gets hidden sometimes otherwise).
set laststatus=2

" Show last comand in the status line.
set showcmd

" End Status Line 

" Start NERDTree 

map <leader>e : NERDTreeToggle<CR>
autocmd StdinReadPre * let s:std_in=1
let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1

" End NERDTree 


" ## added by OPAM user-setup for vim / base ## 93ee63e278bdfc07d1139a748ed3fff2 ## you can edit, but keep this line
let s:opam_share_dir = system("opam config var share")
let s:opam_share_dir = substitute(s:opam_share_dir, '[\r\n]*$', '', '')

let s:opam_configuration = {}

function! OpamConfOcpIndent()
  execute "set rtp^=" . s:opam_share_dir . "/ocp-indent/vim"
endfunction
let s:opam_configuration['ocp-indent'] = function('OpamConfOcpIndent')

function! OpamConfOcpIndex()
  execute "set rtp+=" . s:opam_share_dir . "/ocp-index/vim"
endfunction
let s:opam_configuration['ocp-index'] = function('OpamConfOcpIndex')

function! OpamConfMerlin()
  let l:dir = s:opam_share_dir . "/merlin/vim"
  execute "set rtp+=" . l:dir
endfunction
let s:opam_configuration['merlin'] = function('OpamConfMerlin')

let s:opam_packages = ["ocp-indent", "ocp-index", "merlin"]
let s:opam_check_cmdline = ["opam list --installed --short --safe --color=never"] + s:opam_packages
let s:opam_available_tools = split(system(join(s:opam_check_cmdline)))
for tool in s:opam_packages
  " Respect package order (merlin should be after ocp-index)
  if count(s:opam_available_tools, tool) > 0
    call s:opam_configuration[tool]()
  endif
endfor
" ## end of OPAM user-setup addition for vim / base ## keep this line
" ## added by OPAM user-setup for vim / ocp-indent ## 2704622d309be3cce4198679bf33c889 ## you can edit, but keep this line
if count(s:opam_available_tools,"ocp-indent") == 0
  source "/home/collo/.opam/default/share/ocp-indent/vim/indent/ocaml.vim"
endif
" ## end of OPAM user-setup addition for vim / ocp-indent ## keep this line
