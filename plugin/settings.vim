" Core editor settings for iVim

" --- Display ---
set number
set relativenumber
set cursorline
set signcolumn=yes
set colorcolumn=
set background=dark
syntax on
filetype plugin indent on
set nowrap
set scrolloff=8
set sidescrolloff=8
set laststatus=2
set showcmd
set showmode
set ruler
let &fillchars ..= ',eob: ,vert:│'

" --- Netrw (file explorer) ---
let g:netrw_liststyle = 3
let g:netrw_winsize = 25
let g:netrw_banner = 0
let g:netrw_browse_split = 0

" termguicolors (guarded)
if has('termguicolors') && $TERM !=# 'linux'
  set termguicolors
endif

" --- Search ---
set incsearch
set hlsearch
set ignorecase
set smartcase

" --- Indentation ---
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent
set smartindent
set shiftround

" --- Splits ---
set splitbelow
set splitright

" --- Files/Buffers ---
set hidden
set noswapfile
set nobackup
set nowritebackup
set autoread

" Persistent undo (guarded)
if has('persistent_undo')
  let s:undodir = expand('~/.local/share/vim/undodir')
  if !isdirectory(s:undodir)
    call mkdir(s:undodir, 'p')
  endif
  let &undodir = s:undodir
  set undofile
endif

" --- Completion ---
set wildmenu
set wildmode=longest:full,full
set wildignore+=**/node_modules/**
set wildignore+=**/.git/**
set wildignore+=**/__pycache__/**
set wildignore+=**/target/**
set wildignore+=*.o,*.obj,*.exe,*.dll
set wildignore+=*.pyc,*.pyo
set wildignore+=*.jpg,*.jpeg,*.png,*.gif,*.bmp
set wildignore+=*.DS_Store

" --- Misc ---
set updatetime=300
set belloff=all
set backspace=indent,eol,start
set noerrorbells
set novisualbell

" Mouse (guarded)
if has('mouse')
  set mouse=a
endif
