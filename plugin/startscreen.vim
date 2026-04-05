" iVim start screen — shows keymap help when Vim opens with no file

function! s:ShowStartScreen() abort
  " Only show when Vim opens with no file and a single empty buffer
  if argc() > 0 || line2byte('$') != -1 || &modified
    return
  endif

  " Set up the buffer
  enew
  setlocal bufhidden=wipe buftype=nofile nobuflisted
  setlocal noswapfile nocursorline nocursorcolumn
  setlocal nonumber norelativenumber signcolumn=no

  let l:lines = []

  " ASCII logo
  call add(l:lines, '')
  call add(l:lines, '      _ __   __ _              ')
  call add(l:lines, '     (_)\ \ / /(_)_ __ ___     ')
  call add(l:lines, '     | | \ V / | | ''_ ` _ \   ')
  call add(l:lines, '     | |  \_/  | | | | | | |   ')
  call add(l:lines, '     |_|       |_|_| |_| |_|   ')
  call add(l:lines, '')
  call add(l:lines, '     Plugin-free Vim with Tokyo Night')
  call add(l:lines, '')
  call add(l:lines, '')

  " Keymaps
  call add(l:lines, '   FILE                          SPLITS')
  call add(l:lines, '   Space w     Save               Space sv    Vertical split')
  call add(l:lines, '   Space q     Quit               Space sh    Horizontal split')
  call add(l:lines, '   Space x     Save & quit        Ctrl hjkl   Navigate splits')
  call add(l:lines, '   Space e     File explorer       Space =     Equalize splits')
  call add(l:lines, '')
  call add(l:lines, '   BUFFERS                       SEARCH')
  call add(l:lines, '   Space bn    Next buffer        Space /     Clear highlight')
  call add(l:lines, '   Space bp    Previous buffer    Space sf    Search in files')
  call add(l:lines, '   Space bd    Delete buffer      ')
  call add(l:lines, '   Space bl    List buffers       QUICKFIX')
  call add(l:lines, '                                  Space co    Open quickfix')
  call add(l:lines, '   CLIPBOARD                     Space cc    Close quickfix')
  call add(l:lines, '   Space y     Yank to system     ]q          Next item')
  call add(l:lines, '   Space p     Paste from system  [q          Previous item')
  call add(l:lines, '')
  call add(l:lines, '   TERMINAL                      TABS')
  call add(l:lines, '   Space t     Open terminal      Space Tn    New tab')
  call add(l:lines, '                                  Space Tc    Close tab')
  call add(l:lines, '   OTHER')
  call add(l:lines, '   Space a     Select all')
  call add(l:lines, '')
  call add(l:lines, '')
  call add(l:lines, '   Press any key to start...')

  " Center vertically
  let l:pad = (winheight(0) - len(l:lines)) / 2
  if l:pad > 0
    let l:lines = repeat([''], l:pad) + l:lines
  endif

  setlocal modifiable
  call setline(1, l:lines)
  setlocal nomodifiable nomodified

  " Syntax highlighting for the start screen
  syntax match IvimLogo /_ __   __ _/
  syntax match IvimLogo /(_)\\ \\ \/ \/(_)_ __ ___/
  syntax match IvimLogo /| | \\ V \/ | | '_ ` _ \\/
  syntax match IvimLogo /| |  \\_\/  | | | | | | |/
  syntax match IvimLogo /|_|       |_|_| |_| |_|/
  syntax match IvimSubtitle /Plugin-free Vim with Tokyo Night/
  syntax match IvimHeader /\(FILE\|BUFFERS\|CLIPBOARD\|TERMINAL\|OTHER\|SPLITS\|SEARCH\|QUICKFIX\|TABS\)/
  syntax match IvimKey /Space [a-zA-Z=\/]\+\|Ctrl hjkl\|\]q\|\[q/
  syntax match IvimPrompt /Press any key to start\.\.\./

  highlight link IvimLogo Function
  highlight link IvimSubtitle Comment
  highlight link IvimHeader Type
  highlight link IvimKey Keyword
  highlight link IvimPrompt Comment

  " Any keypress closes the start screen
  nnoremap <buffer><silent> <Space> :enew<CR>
  for key in ['a','b','c','d','e','f','g','h','i','j','k','l','m',
            \ 'n','o','p','q','r','s','t','u','v','w','x','y','z',
            \ 'A','B','C','D','E','F','G','H','I','J','K','L','M',
            \ 'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
            \ '0','1','2','3','4','5','6','7','8','9',
            \ '<CR>', '<Esc>', '<BS>', '<Tab>',
            \ '<Up>', '<Down>', '<Left>', '<Right>']
    execute 'nnoremap <buffer><silent> ' . key . ' :enew<CR>'
  endfor
  " Re-feed command keys so user doesn't have to press twice
  nnoremap <buffer><silent> : :enew<CR>:
  nnoremap <buffer><silent> / :enew<CR>/
  nnoremap <buffer><silent> ? :enew<CR>?
endfunction

augroup ivim_startscreen
  autocmd!
  autocmd VimEnter * call s:ShowStartScreen()
augroup END
