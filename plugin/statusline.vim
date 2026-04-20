" Custom statusline for iVim
" Uses autocommands for active/inactive window differentiation
" Git branch cached per-directory in s:branch_cache so N buffers in the same
" repo cost 1 system() call total; cache is invalidated on ShellCmdPost.

" --- Git branch caching ---
let s:branch_cache = {}

function! s:UpdateGitBranch() abort
  if !executable('git')
    let b:git_branch = ''
    return
  endif
  let l:dir = expand('%:p:h')
  if empty(l:dir)
    let b:git_branch = ''
    return
  endif
  if has_key(s:branch_cache, l:dir)
    let b:git_branch = s:branch_cache[l:dir]
    return
  endif
  let l:branch = system('git -C ' . shellescape(l:dir) . ' rev-parse --abbrev-ref HEAD 2>/dev/null')
  if v:shell_error
    let l:branch = ''
  else
    let l:branch = substitute(l:branch, '\n', '', 'g')
  endif
  let s:branch_cache[l:dir] = l:branch
  let b:git_branch = l:branch
endfunction

function! s:InvalidateBranchCache() abort
  let s:branch_cache = {}
  call s:UpdateGitBranch()
endfunction

augroup ivim_statusline
  autocmd!
  autocmd BufEnter * call s:UpdateGitBranch()
  autocmd ShellCmdPost * call s:InvalidateBranchCache()
  autocmd WinEnter,BufWinEnter * call s:SetActiveStatusline()
  autocmd WinLeave * call s:SetInactiveStatusline()
augroup END

" --- Mode map ---
let s:mode_map = {
      \ 'n':      ['NORMAL',  'StlModeNormal'],
      \ 'i':      ['INSERT',  'StlModeInsert'],
      \ 'v':      ['VISUAL',  'StlModeVisual'],
      \ 'V':      ['V-LINE',  'StlModeVisual'],
      \ "\<C-v>": ['V-BLOCK', 'StlModeVisual'],
      \ 's':      ['SELECT',  'StlModeVisual'],
      \ 'S':      ['S-LINE',  'StlModeVisual'],
      \ "\<C-s>": ['S-BLOCK', 'StlModeVisual'],
      \ 'R':      ['REPLACE', 'StlModeReplace'],
      \ 'c':      ['COMMAND', 'StlModeCommand'],
      \ 't':      ['TERMINAL','StlModeNormal'],
      \ }

function! StlMode() abort
  let l:m = mode()
  if has_key(s:mode_map, l:m)
    return s:mode_map[l:m][0]
  endif
  return 'NORMAL'
endfunction

function! StlModeHighlight() abort
  let l:m = mode()
  if has_key(s:mode_map, l:m)
    return s:mode_map[l:m][1]
  endif
  return 'StlModeNormal'
endfunction

function! StlGitBranch() abort
  let l:branch = get(b:, 'git_branch', '')
  if empty(l:branch)
    return ''
  endif
  return '  ' . l:branch . ' '
endfunction

function! StlFilename() abort
  let l:name = expand('%:~:.')
  if empty(l:name)
    let l:name = '[No Name]'
  endif
  return l:name
endfunction

function! StlModified() abort
  if &modified
    return ' [+]'
  elseif !&modifiable
    return ' [-]'
  endif
  return ''
endfunction

function! StlReadonly() abort
  if &readonly
    return ' [RO]'
  endif
  return ''
endfunction

" --- Active statusline ---
function! s:SetActiveStatusline() abort
  " Don't overwrite netrw's custom statusline
  if &filetype ==# 'netrw'
    return
  endif
  if has('patch-8.2.2854')
    let &l:statusline = ''
          \ . '%{%"%#" . StlModeHighlight() . "#"%}'
          \ . ' %{StlMode()} '
          \ . '%#StlBranch#'
          \ . '%{StlGitBranch()}'
          \ . '%#StlFile#'
          \ . ' %{StlFilename()}'
          \ . '%#StlFileModified#'
          \ . '%{StlModified()}'
          \ . '%#StlFile#'
          \ . '%{StlReadonly()}'
          \ . '%<'
          \ . '%#StlInfo#'
          \ . '%='
          \ . ' %{&filetype} '
          \ . '│ %{&fileencoding?&fileencoding:&encoding} '
          \ . '│ %{&fileformat} '
          \ . '%#StlPosition#'
          \ . ' %l:%c %P '
  else
    let &l:statusline = ''
          \ . '%#StlModeNormal#'
          \ . ' %{StlMode()} '
          \ . '%#StlBranch#'
          \ . '%{StlGitBranch()}'
          \ . '%#StlFile#'
          \ . ' %{StlFilename()}'
          \ . '%#StlFileModified#'
          \ . '%{StlModified()}'
          \ . '%#StlFile#'
          \ . '%{StlReadonly()}'
          \ . '%<'
          \ . '%#StlInfo#'
          \ . '%='
          \ . ' %{&filetype} '
          \ . '│ %{&fileencoding?&fileencoding:&encoding} '
          \ . '│ %{&fileformat} '
          \ . '%#StlPosition#'
          \ . ' %l:%c %P '
  endif
endfunction

" --- Inactive statusline ---
function! s:SetInactiveStatusline() abort
  if &filetype ==# 'netrw'
    return
  endif
  let &l:statusline = ''
        \ . '%#StlInactive#'
        \ . ' NORMAL '
        \ . ' %{StlGitBranch()}'
        \ . ' %{StlFilename()}'
        \ . '%{StlModified()}'
        \ . '%{StlReadonly()}'
        \ . '%<'
        \ . '%='
        \ . ' %{&filetype} '
        \ . '│ %l:%c %P '
endfunction

" --- Tabline ---
function! StlTabLabel(n) abort
  let l:buflist = tabpagebuflist(a:n)
  let l:winnr = tabpagewinnr(a:n)
  let l:name = bufname(l:buflist[l:winnr - 1])
  let l:name = fnamemodify(l:name, ':t')
  if empty(l:name)
    let l:name = '[No Name]'
  endif
  if getbufvar(l:buflist[l:winnr - 1], '&modified')
    let l:name .= ' [+]'
  endif
  return ' ' . l:name . ' '
endfunction

function! StlTabLine() abort
  let l:s = ''
  for i in range(tabpagenr('$'))
    if i + 1 == tabpagenr()
      let l:s .= '%#TabLineSel#'
    else
      let l:s .= '%#TabLine#'
    endif
    let l:s .= '%' . (i + 1) . 'T'
    let l:s .= StlTabLabel(i + 1)
  endfor
  let l:s .= '%T%#TabLineFill#'
  return l:s
endfunction
set tabline=%!StlTabLine()

" Initialize for the first window
call s:SetActiveStatusline()
