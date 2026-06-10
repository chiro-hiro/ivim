setlocal conceallevel=2
setlocal concealcursor=nvic
syntax match NetrwTreeSmooth /|/ conceal cchar=│
setlocal statusline=%#StlFile#\ Explorer

nnoremap <buffer><silent> <CR> :call IvimNetrwOpenInEditor()<CR>
nmap <buffer><silent> <2-LeftMouse> <CR>

" Revert the setlocal options, buffer mappings, and tree-conceal syntax on
" filetype change so none of it leaks into a non-netrw buffer.
let b:undo_ftplugin = get(b:, 'undo_ftplugin', '') . '|setlocal cole< cocu< stl<|silent! nunmap <buffer> <CR>|silent! nunmap <buffer> <2-LeftMouse>|silent! syntax clear NetrwTreeSmooth'
