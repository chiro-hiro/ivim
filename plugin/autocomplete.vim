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
"   - Normalizes b:ivim_complete_triggers into a longest-first list so
"     multi-char operators (-> ::) match before single chars (. >)
"   - Installs a <buffer>-local TextChangedI autocmd so disabled
"     buffers pay zero per-keystroke cost
function! s:SetupBuffer() abort
  " Always clear any prior <buffer> autocmd first — without this, switching
  " a buffer's filetype from e.g. `c` to `markdown` would leave the old
  " TextChangedI handler in place because the prose / disable early-returns
  " below would skip past the autocmd! line.
  augroup ivim_autocomplete_buf
    autocmd! * <buffer>
  augroup END

  if get(b:, 'ivim_autocomplete_disable', 0)
    return
  endif
  if has_key(s:prose_filetypes, &filetype)
    return
  endif

  " Sort longest-first so a multi-char operator (e.g. '->') is tested before
  " its trailing single char, and so a bare '>' never triggers on its own —
  " only the full '->' sequence does. Drop empty entries defensively.
  let l:triggers = filter(copy(get(b:, 'ivim_complete_triggers', ['.'])), '!empty(v:val)')
  let b:ivim_triggers = sort(l:triggers, {a, b -> strlen(b) - strlen(a)})

  augroup ivim_autocomplete_buf
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

  " Omnifunc dispatch on a configured trigger sequence (. -> :: …).
  " &omnifunc is read live, not cached at FileType, so a buffer whose
  " omnifunc is set/cleared after the fact still dispatches correctly.
  if !empty(&omnifunc)
    for l:trig in get(b:, 'ivim_triggers', [])
      let l:tlen = strlen(l:trig)
      let l:start = l:col - 1 - l:tlen
      if l:start >= 0 && strpart(l:line, l:start, l:tlen) ==# l:trig
        " Skip a repeated single-char trigger (the 2nd char of .. :: >>):
        " omnifunc already fired on the first; re-firing wastes time and
        " can leave Vim stuck in a confused completion state.
        if l:tlen == 1 && l:start >= 1 && l:line[l:start - 1] ==# l:trig
          return
        endif
        call feedkeys("\<C-x>\<C-o>", 'n')
        return
      endif
    endfor
  endif

  " Keyword: fire only on the second word char of a new word. Re-firing every
  " keystroke within a word thrashes the popup open/close cycle and stops the
  " user from typing past suggestions they want to ignore. Measure the trailing
  " \k run before the cursor with matchstr + strchars (character-aware) rather
  " than byte subscripts (l:line[l:col - 2]), so multibyte word characters
  " (accented Latin, Cyrillic, CJK) count as whole characters instead of being
  " split into lead/trailing bytes — the latter silently suppressed completion
  " around any non-ASCII text.
  if strchars(matchstr(strpart(l:line, 0, l:col - 1), '\k*$')) == 2
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
