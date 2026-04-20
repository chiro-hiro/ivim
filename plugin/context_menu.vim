" Right-click context menu — Copy / Cut / Paste via system clipboard
" Uses Vim's native PopUp menu: :popup PopUp triggered by <RightRelease>.
" Items are defined with *noremenu per mode so they execute the raw key
" sequences regardless of user remappings.

if has('clipboard')
  " Normal mode: operate on the current line
  nnoremenu <silent> PopUp.Copy      "+yy
  nnoremenu <silent> PopUp.Cut       "+dd
  nnoremenu <silent> PopUp.Paste     "+p

  " Visual mode: operate on the selection
  vnoremenu <silent> PopUp.Copy      "+y
  vnoremenu <silent> PopUp.Cut       "+d
  vnoremenu <silent> PopUp.Paste     "+p

  " Insert mode: only Paste is meaningful
  inoremenu <silent> PopUp.Paste     <C-r>+

  " <Cmd> (patch-8.2.1978) runs an Ex command without changing mode —
  " ideal for preserving insert mode across the popup. Older Vim falls
  " back to :popup / <C-o>:popup with a brief mode switch.
  if has('patch-8.2.1978')
    nnoremap <silent> <RightRelease> <Cmd>popup PopUp<CR>
    vnoremap <silent> <RightRelease> <Cmd>popup PopUp<CR>
    inoremap <silent> <RightRelease> <Cmd>popup PopUp<CR>
  else
    nnoremap <silent> <RightRelease> :popup PopUp<CR>
    vnoremap <silent> <RightRelease> :popup PopUp<CR>
    inoremap <silent> <RightRelease> <C-o>:popup PopUp<CR>
  endif
else
  " Fallback: same warning surface as <leader>y/p when +clipboard is absent
  nnoremap <silent> <RightRelease> :echo 'Clipboard not available: Vim compiled without +clipboard'<CR>
  vnoremap <silent> <RightRelease> :<C-u>echo 'Clipboard not available: Vim compiled without +clipboard'<CR>
  inoremap <silent> <RightRelease> <C-o>:echo 'Clipboard not available: Vim compiled without +clipboard'<CR>
endif
