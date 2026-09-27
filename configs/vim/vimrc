" Install vim-plug to manage plugins
let data_dir = '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
"
" Install plugins
call plug#begin()
Plug 'wellle/context.vim'
call plug#end()
"
" This disables compatibility with the original vi editor, making Vim behave more like Vim and less like vi
set nocompatible
" Enables automatic detection of the file type based on the files extensio 
filetype on
" Enables loading of filetype-specific plugins.
filetype plugin on
" Enables filetype-specific indentation rules
filetype indent on
" Enables syntax highlighting for the current buffer
syntax on
" Highlights the current line
set cursorline
" Highlights the column of the cursor
set cursorcolumn
" Converts tabs to spaces when you press the Tab key
set expandtab
" Disables line wrapping, so long lines will not be visually wrapped
set nowrap
" Shows the matching characters as you type during a search
set incsearch
" Ignores case when searching
set ignorecase
" Overrides the ignorecase setting if the search pattern contains uppercase characters.
set smartcase
" Highlights matching parentheses, brackets, and braces
set showmatch
" Highlight all search results
set hlsearch
" Command history length
set history=10000
" Number lines
set nu
" Set shift width to 4 spaces.
set shiftwidth=4
" Set tab width to 4 columns.
set tabstop=4
" Copy text to clipboard
set clipboard=unnamedplus
" Ctrl + > move to next word
noremap <C-Right> w
" Ctrl + < move to previous word
noremap <C-Left> b 
" turn relative line numbers on
:set relativenumber
" set folding by indentation
set foldmethod=indent
