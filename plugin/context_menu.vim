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
" In Visual mode Vim's default <RightMouse> press extends the selection to
" the click point *before* <RightRelease> fires, so Copy/Cut would act on the
" wrong range. Neutralize the press (and drag) so the menu operates on the
" selection the user actually made. Normal/insert <RightMouse> has no
" destructive default, so it is left alone.
vnoremap <silent> <RightMouse> <Nop>
vnoremap <silent> <RightDrag>  <Nop>

if has('patch-8.2.1978')
  nnoremap <silent> <RightRelease> <Cmd>popup PopUp<CR>
  vnoremap <silent> <RightRelease> <Cmd>popup PopUp<CR>
  inoremap <silent> <RightRelease> <Cmd>popup PopUp<CR>
else
  " No insert-mode right-click on older Vim: the only way to reach the popup
  " from insert mode is <C-o>, which switches to Normal mode so the popup
  " resolves the Normal-mode Paste ("+p) instead of the insert-mode <C-r>+,
  " pasting with the wrong semantics. Leave insert mode's default intact.
  nnoremap <silent> <RightRelease> :popup PopUp<CR>
  vnoremap <silent> <RightRelease> :popup PopUp<CR>
endif
