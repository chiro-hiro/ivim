" Right-click context menu — Copy / Cut / Paste via system clipboard
" Uses Vim's native PopUp menu: :popup PopUp triggered by <RightRelease>.
" Items are defined with *noremenu per mode so they execute the raw key
" sequences regardless of user remappings.
"
" The feature is strictly opt-in on +clipboard. Without it there is no
" useful work the menu could do (every item depends on the "+" register),
" and remapping <RightRelease> to anything else would override Vim's
" default right-click behaviour (visual-selection extension) for no gain.

if !has('clipboard')
  finish
endif

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
