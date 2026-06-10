setlocal conceallevel=2
setlocal concealcursor=nvic
syntax match NetrwTreeSmooth /|/ conceal cchar=│
setlocal statusline=%#StlFile#\ Explorer

nnoremap <buffer><silent> <CR> :call IvimNetrwOpenInEditor()<CR>
nmap <buffer><silent> <2-LeftMouse> <CR>

" Deliberately NO b:undo_ftplugin here. netrw re-fires FileType on its own
" buffer during routine operations (list-style toggle `i`, directory change),
" and any b:undo_ftplugin makes Vim unlet b:did_ftplugin and *reload* netrw's
" own ftplugin mid-operation — which throws `E749: Empty buffer`. netrw buffers
" are disposable (bufhidden=wipe) and are never re-typed to another filetype,
" so there is no setlocal/b:ivim_* state to undo in the first place.
