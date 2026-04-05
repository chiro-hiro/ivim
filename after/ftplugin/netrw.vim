setlocal conceallevel=2
setlocal concealcursor=nvic
syntax match NetrwTreeSmooth /|/ conceal cchar=│
setlocal statusline=%#StlFile#\ Explorer

nnoremap <buffer><silent> <CR> :call IvimNetrwOpenInEditor()<CR>
nmap <buffer><silent> <2-LeftMouse> <CR>
