" IDE-style auto-completion engine
" Dispatches between keyword completion (<C-n>) and omnifunc (<C-x><C-o>)
" based on the last character typed in insert mode.

set completeopt=menuone,noinsert,noselect
set shortmess+=c
set pumheight=10

" Prose filetypes: autocomplete is disabled entirely.
let s:prose_filetypes = {'markdown': 1, 'gitcommit': 1, 'text': 1, 'help': 1}

" Per-buffer setup runs once on FileType. It:
"   - Bails out for prose filetypes and buffers with the disable flag
"   - Precompiles b:ivim_complete_triggers into a regex char class
"   - Caches whether omnifunc is set
"   - Installs a <buffer>-local TextChangedI autocmd so disabled
"     buffers pay zero per-keystroke cost
function! s:SetupBuffer() abort
  if get(b:, 'ivim_autocomplete_disable', 0)
    return
  endif
  if has_key(s:prose_filetypes, &filetype)
    return
  endif

  let l:triggers = get(b:, 'ivim_complete_triggers', ['.'])
  let b:ivim_trigger_pattern =
        \ empty(l:triggers)
        \ ? ''
        \ : '[' . escape(join(l:triggers, ''), ']\^-') . ']'
  let b:ivim_has_omnifunc = !empty(&omnifunc)

  augroup ivim_autocomplete_buf
    autocmd! * <buffer>
    autocmd TextChangedI <buffer> call <SID>MaybeTrigger()
  augroup END
endfunction

function! s:MaybeTrigger() abort
  if pumvisible()
    return
  endif
  let l:col = col('.')
  if l:col < 2
    return
  endif
  let l:line = getline('.')
  let l:ch = l:line[l:col - 2]

  if b:ivim_has_omnifunc
        \ && !empty(b:ivim_trigger_pattern)
        \ && l:ch =~# b:ivim_trigger_pattern
    " Skip duplicates like :: .. >> — omnifunc already fired on the first
    " char; re-firing on the second wastes time and can leave Vim stuck
    " in a confused completion state while typeahead drains.
    if l:col >= 3 && l:line[l:col - 3] ==# l:ch
      return
    endif
    call feedkeys("\<C-x>\<C-o>", 'n')
  " Keyword: fire only on the second word char of a new word. Re-firing every
  " keystroke within a word thrashes the popup open/close cycle and stops
  " the user from typing past suggestions they want to ignore.
  elseif l:ch =~# '\k'
        \ && l:col >= 3 && l:line[l:col - 3] =~# '\k'
        \ && (l:col < 4 || l:line[l:col - 4] !~# '\k')
    call feedkeys("\<C-n>", 'n')
  endif
endfunction

augroup ivim_autocomplete
  autocmd!
  autocmd FileType * call s:SetupBuffer()
augroup END

" Popup navigation keymaps — all <expr> so they fall through when popup
" is not visible (Tab still indents, CR still inserts newline, etc.)
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

if has('patch-8.0.1775')
  " complete_info() lets us keep <CR> as newline when no item is selected
  inoremap <expr> <CR>
        \ pumvisible() && complete_info(['selected']).selected != -1
        \ ? "\<C-y>"
        \ : "\<CR>"
else
  inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
endif

inoremap <expr> <Esc> pumvisible() ? "\<C-e>\<Esc>" : "\<Esc>"
