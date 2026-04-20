" Key mappings for iVim
" Leader is set in vimrc (Space)
" Only adds new <leader> bindings — does NOT override any default Vim keys

" === File/Buffer Navigation ===
nnoremap <leader>w :w<CR>
nnoremap <leader>q :confirm qall<CR>
nnoremap <leader>x :xall<CR>

function! s:CloseTerminals() abort
  for buf in getbufinfo()
    if getbufvar(buf.bufnr, '&buftype') ==# 'terminal'
      execute buf.bufnr . 'bwipeout!'
    endif
  endfor
endfunction

augroup ivim_terminal_cleanup
  autocmd!
  autocmd QuitPre * call s:CloseTerminals()
augroup END
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>
nnoremap <leader>bl :ls<CR>

" === File Explorer ===
function! s:ToggleExplorer() abort
  for win in range(1, winnr('$'))
    if getbufvar(winbufnr(win), '&filetype') ==# 'netrw'
      Lexplore
      return
    endif
  endfor
  Lexplore
  vertical resize 30
endfunction
nnoremap <leader>e :call <SID>ToggleExplorer()<CR>

" --- Netrw file opening (global functions, called from after/ftplugin/netrw.vim) ---
" Build full path for file under cursor by walking up the netrw tree
function! IvimNetrwGetTreePath() abort
  let l:line = getline('.')
  let l:fname = substitute(l:line, '^[\| ]*', '', '')

  if l:fname =~# '^\s*$'
    return ''
  endif

  let l:prefix = matchstr(l:line, '^[\| ]*')
  let l:depth = count(l:prefix, '|')

  let l:parts = [l:fname]
  let l:target_depth = l:depth - 1
  let l:lnum = line('.') - 1
  while l:target_depth >= 0 && l:lnum >= 1
    let l:prev = getline(l:lnum)
    let l:prev_prefix = matchstr(l:prev, '^[\| ]*')
    let l:prev_depth = count(l:prev_prefix, '|')
    if l:prev_depth == l:target_depth
      let l:prev_name = substitute(l:prev, '^[\| ]*', '', '')
      if l:prev_name =~# '/$'
        call insert(l:parts, l:prev_name, 0)
        let l:target_depth -= 1
      endif
    endif
    let l:lnum -= 1
  endwhile

  return join(l:parts, '')
endfunction

" Open file in editor window, never in terminal or netrw
function! IvimNetrwOpenInEditor() abort
  if !exists('b:netrw_curdir')
    return
  endif
  let l:relpath = IvimNetrwGetTreePath()
  if empty(l:relpath)
    return
  endif

  let l:fullpath = simplify(b:netrw_curdir . '/' . l:relpath)

  " Let netrw handle directories (expand/collapse)
  if isdirectory(l:fullpath)
    execute "normal \<Plug>NetrwLocalBrowseCheck"
    return
  endif

  if !filereadable(l:fullpath)
    execute "normal \<Plug>NetrwLocalBrowseCheck"
    return
  endif

  " Find an editor window (not netrw, not terminal)
  let l:target = -1
  for w in range(1, winnr('$'))
    let l:bt = getbufvar(winbufnr(w), '&buftype')
    let l:ft = getbufvar(winbufnr(w), '&filetype')
    if l:bt !=# 'terminal' && l:ft !=# 'netrw'
      let l:target = w
      break
    endif
  endfor

  if l:target == -1
    vertical rightbelow new
    let l:target = winnr()
  endif

  execute l:target . 'wincmd w'
  execute 'edit ' . fnameescape(l:fullpath)
endfunction

" === Splits ===
nnoremap <leader>sv :vsplit<CR>
nnoremap <leader>sh :split<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <leader>= <C-w>=

" === Search ===
nnoremap <leader>/ :nohlsearch<CR>

" Search in files — prompts for pattern, uses vimgrep + quickfix
function! s:SearchInFiles() abort
  let l:pattern = input('Search: ')
  if empty(l:pattern)
    return
  endif
  let l:escaped = escape(l:pattern, '/\|')
  try
    execute 'vimgrep /\V' . l:escaped . '/ **/*'
    copen
  catch
    echohl WarningMsg
    echo 'No matches found for: ' . l:pattern
    echohl None
  endtry
endfunction
nnoremap <leader>sf :call <SID>SearchInFiles()<CR>

" === Quickfix ===
nnoremap <leader>co :copen<CR>
nnoremap <leader>cc :cclose<CR>
nnoremap ]q :cnext<CR>
nnoremap [q :cprevious<CR>

" === Clipboard (guarded) ===
if has('clipboard')
  vnoremap <leader>y "+y
  nnoremap <leader>y "+y
  nnoremap <leader>p "+p
  nnoremap <leader>P "+P
  vnoremap <leader>p "+p
else
  nnoremap <leader>y :echo 'Clipboard not available: Vim compiled without +clipboard'<CR>
  vnoremap <leader>y :<C-u>echo 'Clipboard not available: Vim compiled without +clipboard'<CR>
  nnoremap <leader>p :echo 'Clipboard not available: Vim compiled without +clipboard'<CR>
endif

" === Select all ===
nnoremap <leader>a ggVG

" === Terminal (guarded) ===
if has('terminal')
  function! s:OpenTerminal() abort
    " Move to a non-netrw, non-terminal window before opening
    for w in range(1, winnr('$'))
      let l:bt = getbufvar(winbufnr(w), '&buftype')
      let l:ft = getbufvar(winbufnr(w), '&filetype')
      if l:bt !=# 'terminal' && l:ft !=# 'netrw'
        execute w . 'wincmd w'
        break
      endif
    endfor
    let l:rcfile = fnamemodify(resolve(expand('<script>:p')), ':h:h') . '/terminal.bashrc'
    " Use term_start() with a list to safely pass paths containing spaces
    " (Vim's :terminal splits the command on whitespace regardless of quoting)
    below new
    call term_start(['bash', '--init-file', l:rcfile], {
          \ 'curwin': 1,
          \ 'term_rows': 15,
          \ 'term_finish': 'close',
          \ })
  endfunction
  nnoremap <leader>t :call <SID>OpenTerminal()<CR>

  " Clean up netrw mouse mappings that leak into terminal buffers
  augroup ivim_terminal_mouse
    autocmd!
    autocmd TerminalOpen * silent! nunmap <buffer> <LeftMouse>
    autocmd TerminalOpen * silent! nunmap <buffer> <2-LeftMouse>
  augroup END
else
  nnoremap <leader>t :echo 'Terminal not available: Vim compiled without +terminal'<CR>
endif

" === Tabs ===
nnoremap <leader>Tn :tabnew<CR>
nnoremap <leader>Tc :tabclose<CR>
