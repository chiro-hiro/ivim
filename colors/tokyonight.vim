" Tokyo Night (Night variant) colorscheme for Vim
" Plugin-free implementation

set background=dark
hi clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'tokyonight'

" --- Palette ---
" Background:       #1a1b26  cterm=234
" Foreground:       #c0caf5  cterm=189
" Selection:        #283457  cterm=236
" Comment:          #565f89  cterm=60
" Strings:          #9ece6a  cterm=149
" Functions:        #7aa2f7  cterm=111
" Keywords:         #9d7cd8  cterm=140
" Types:            #2ac3de  cterm=44
" Numbers:          #ff9e64  cterm=209
" Red:              #f7768e  cterm=204
" Yellow:           #e0af68  cterm=179
" Additional:
" Dark bg:          #16161e  cterm=233
" Light bg:         #292e42  cterm=236
" Dark fg:          #3b4261  cterm=59
" Terminal black:   #414868  cterm=59
" Gutter:           #3b4261  cterm=59
" Menu bg:          #1f2335  cterm=235

" --- Syntax ---
hi Normal       guifg=#c0caf5 guibg=#1a1b26 ctermfg=189 ctermbg=234
hi Comment      guifg=#565f89 guibg=NONE    ctermfg=60  ctermbg=NONE gui=italic cterm=italic
hi String       guifg=#9ece6a guibg=NONE    ctermfg=149 ctermbg=NONE
hi Function     guifg=#7aa2f7 guibg=NONE    ctermfg=111 ctermbg=NONE
hi Keyword      guifg=#9d7cd8 guibg=NONE    ctermfg=140 ctermbg=NONE
hi Type         guifg=#2ac3de guibg=NONE    ctermfg=44  ctermbg=NONE
hi Number       guifg=#ff9e64 guibg=NONE    ctermfg=209 ctermbg=NONE
hi Constant     guifg=#ff9e64 guibg=NONE    ctermfg=209 ctermbg=NONE
hi Boolean      guifg=#ff9e64 guibg=NONE    ctermfg=209 ctermbg=NONE
hi Identifier   guifg=#c0caf5 guibg=NONE    ctermfg=189 ctermbg=NONE
hi Statement    guifg=#9d7cd8 guibg=NONE    ctermfg=140 ctermbg=NONE
hi PreProc      guifg=#7dcfff guibg=NONE    ctermfg=117 ctermbg=NONE
hi Operator     guifg=#89ddff guibg=NONE    ctermfg=117 ctermbg=NONE
hi Special      guifg=#7dcfff guibg=NONE    ctermfg=117 ctermbg=NONE
hi Delimiter    guifg=#c0caf5 guibg=NONE    ctermfg=189 ctermbg=NONE
hi Error        guifg=#f7768e guibg=NONE    ctermfg=204 ctermbg=NONE
hi Todo         guifg=#e0af68 guibg=NONE    ctermfg=179 ctermbg=NONE gui=bold cterm=bold
hi ModeMsg      guifg=#9ece6a guibg=NONE    ctermfg=149 ctermbg=NONE gui=bold cterm=bold
hi Underlined   guifg=#7aa2f7 guibg=NONE    ctermfg=111 ctermbg=NONE gui=underline cterm=underline

" --- UI ---
hi CursorLine   guifg=NONE    guibg=#292e42 ctermfg=NONE ctermbg=236 cterm=NONE
hi CursorLineNr guifg=#c0caf5 guibg=#292e42 ctermfg=189  ctermbg=236 gui=bold cterm=bold
hi LineNr       guifg=#3b4261 guibg=NONE    ctermfg=59   ctermbg=NONE
hi Visual       guifg=NONE    guibg=#283457 ctermfg=NONE ctermbg=236
hi Search       guifg=#1a1b26 guibg=#e0af68 ctermfg=234  ctermbg=179
hi IncSearch    guifg=#1a1b26 guibg=#ff9e64 ctermfg=234  ctermbg=209
hi StatusLine   guifg=#c0caf5 guibg=#1f2335 ctermfg=189  ctermbg=235
hi StatusLineNC guifg=#565f89 guibg=#1f2335 ctermfg=60   ctermbg=235
hi VertSplit    guifg=#1f2335 guibg=#1a1b26 ctermfg=235  ctermbg=234
hi Pmenu        guifg=#c0caf5 guibg=#1f2335 ctermfg=189  ctermbg=235
hi PmenuSel     guifg=#1a1b26 guibg=#7aa2f7 ctermfg=234  ctermbg=111
hi TabLine      guifg=#565f89 guibg=#1f2335 ctermfg=60   ctermbg=235
hi TabLineSel   guifg=#c0caf5 guibg=#1a1b26 ctermfg=189  ctermbg=234 gui=bold cterm=bold
hi TabLineFill  guifg=NONE    guibg=#1f2335 ctermfg=NONE ctermbg=235
hi SignColumn   guifg=#3b4261 guibg=#1a1b26 ctermfg=59   ctermbg=234
hi FoldColumn   guifg=#565f89 guibg=#1a1b26 ctermfg=60   ctermbg=234
hi Folded       guifg=#565f89 guibg=#1f2335 ctermfg=60   ctermbg=235
hi MatchParen   guifg=#ff9e64 guibg=NONE    ctermfg=209  ctermbg=NONE gui=bold cterm=bold
hi ColorColumn  guifg=NONE    guibg=#1f2335 ctermfg=NONE ctermbg=235
hi NonText      guifg=#3b4261 guibg=NONE    ctermfg=59   ctermbg=NONE
hi SpecialKey   guifg=#3b4261 guibg=NONE    ctermfg=59   ctermbg=NONE
hi Conceal      guifg=#3b4261 guibg=NONE    ctermfg=59   ctermbg=NONE
hi Directory    guifg=#7aa2f7 guibg=NONE    ctermfg=111  ctermbg=NONE gui=bold cterm=bold
hi Title        guifg=#7aa2f7 guibg=NONE    ctermfg=111  ctermbg=NONE gui=bold cterm=bold
hi WildMenu     guifg=#1a1b26 guibg=#7aa2f7 ctermfg=234  ctermbg=111  gui=bold cterm=bold
hi PmenuSbar    guifg=NONE    guibg=#292e42 ctermfg=NONE ctermbg=236
hi PmenuThumb   guifg=NONE    guibg=#565f89 ctermfg=NONE ctermbg=60

" --- Diff ---
hi DiffAdd      guifg=NONE    guibg=#20303b ctermfg=NONE ctermbg=23
hi DiffChange   guifg=NONE    guibg=#1f2a48 ctermfg=NONE ctermbg=17
hi DiffDelete   guifg=#f7768e guibg=#37222c ctermfg=204  ctermbg=52
hi DiffText     guifg=NONE    guibg=#394b70 ctermfg=NONE ctermbg=60  gui=bold cterm=bold

" --- Messages ---
hi ErrorMsg     guifg=#f7768e guibg=NONE    ctermfg=204  ctermbg=NONE gui=bold cterm=bold
hi WarningMsg   guifg=#e0af68 guibg=NONE    ctermfg=179  ctermbg=NONE gui=bold cterm=bold
hi MoreMsg      guifg=#9ece6a guibg=NONE    ctermfg=149  ctermbg=NONE
hi Question     guifg=#7aa2f7 guibg=NONE    ctermfg=111  ctermbg=NONE

" --- Statusline mode highlight groups (used by statusline.vim) ---
hi StlModeNormal  guifg=#1a1b26 guibg=#7aa2f7 ctermfg=234 ctermbg=111 gui=bold cterm=bold
hi StlModeInsert  guifg=#1a1b26 guibg=#9ece6a ctermfg=234 ctermbg=149 gui=bold cterm=bold
hi StlModeVisual  guifg=#1a1b26 guibg=#9d7cd8 ctermfg=234 ctermbg=140 gui=bold cterm=bold
hi StlModeReplace guifg=#1a1b26 guibg=#f7768e ctermfg=234 ctermbg=204 gui=bold cterm=bold
hi StlModeCommand guifg=#1a1b26 guibg=#ff9e64 ctermfg=234 ctermbg=209 gui=bold cterm=bold

hi StlBranch      guifg=#7aa2f7 guibg=#1f2335 ctermfg=111 ctermbg=235
hi StlFile        guifg=#c0caf5 guibg=#1f2335 ctermfg=189 ctermbg=235
hi StlFileModified guifg=#e0af68 guibg=#1f2335 ctermfg=179 ctermbg=235
hi StlInfo        guifg=#565f89 guibg=#1f2335 ctermfg=60  ctermbg=235
hi StlPosition    guifg=#c0caf5 guibg=#292e42 ctermfg=189 ctermbg=236

hi StlInactive    guifg=#565f89 guibg=#1f2335 ctermfg=60  ctermbg=235

" --- Terminal ANSI colors (Tokyo Night) ---
if has('terminal')
  let g:terminal_ansi_colors = [
        \ '#414868', '#f7768e', '#9ece6a', '#e0af68',
        \ '#7aa2f7', '#9d7cd8', '#2ac3de', '#c0caf5',
        \ '#565f89', '#f7768e', '#9ece6a', '#e0af68',
        \ '#7aa2f7', '#9d7cd8', '#2ac3de', '#c0caf5',
        \ ]
endif

" --- Filetype: TOML ---
" Keys are white + bold; tables (section headers) stay blue + bold to
" preserve visual hierarchy between sections and their contents.
hi tomlTable      guifg=#7aa2f7 guibg=NONE    ctermfg=111 ctermbg=NONE gui=bold cterm=bold
hi tomlTableArray guifg=#7aa2f7 guibg=NONE    ctermfg=111 ctermbg=NONE gui=bold cterm=bold
hi tomlKey        guifg=#c0caf5 guibg=NONE    ctermfg=189 ctermbg=NONE gui=bold cterm=bold
hi tomlKeyDq      guifg=#c0caf5 guibg=NONE    ctermfg=189 ctermbg=NONE gui=bold cterm=bold
hi tomlKeySq      guifg=#c0caf5 guibg=NONE    ctermfg=189 ctermbg=NONE gui=bold cterm=bold
hi tomlString     guifg=#9ece6a guibg=NONE    ctermfg=149 ctermbg=NONE
hi tomlInteger    guifg=#ff9e64 guibg=NONE    ctermfg=209 ctermbg=NONE
hi tomlFloat      guifg=#ff9e64 guibg=NONE    ctermfg=209 ctermbg=NONE
hi tomlBoolean    guifg=#ff9e64 guibg=NONE    ctermfg=209 ctermbg=NONE
hi tomlDate       guifg=#9d7cd8 guibg=NONE    ctermfg=140 ctermbg=NONE
hi tomlEscape     guifg=#9d7cd8 guibg=NONE    ctermfg=140 ctermbg=NONE
hi tomlComment    guifg=#565f89 guibg=NONE    ctermfg=60  ctermbg=NONE gui=italic cterm=italic

" --- Filetype: YAML ---
" Keys are the structural anchors — white + bold.
hi yamlBlockMappingKey guifg=#c0caf5 guibg=NONE ctermfg=189 ctermbg=NONE gui=bold cterm=bold
hi yamlFlowMappingKey  guifg=#c0caf5 guibg=NONE ctermfg=189 ctermbg=NONE gui=bold cterm=bold
hi yamlBool            guifg=#ff9e64 guibg=NONE ctermfg=209 ctermbg=NONE
hi yamlInteger         guifg=#ff9e64 guibg=NONE ctermfg=209 ctermbg=NONE
hi yamlFloat           guifg=#ff9e64 guibg=NONE ctermfg=209 ctermbg=NONE
hi yamlNull            guifg=#9d7cd8 guibg=NONE ctermfg=140 ctermbg=NONE
hi yamlDocumentStart   guifg=#9d7cd8 guibg=NONE ctermfg=140 ctermbg=NONE
hi yamlDocumentEnd     guifg=#9d7cd8 guibg=NONE ctermfg=140 ctermbg=NONE
hi yamlAnchor          guifg=#e0af68 guibg=NONE ctermfg=179 ctermbg=NONE
hi yamlAlias           guifg=#e0af68 guibg=NONE ctermfg=179 ctermbg=NONE
hi yamlNodeTag         guifg=#e0af68 guibg=NONE ctermfg=179 ctermbg=NONE
hi yamlFlowString      guifg=#9ece6a guibg=NONE ctermfg=149 ctermbg=NONE
hi yamlSingleEscape    guifg=#9d7cd8 guibg=NONE ctermfg=140 ctermbg=NONE
hi yamlComment         guifg=#565f89 guibg=NONE ctermfg=60  ctermbg=NONE gui=italic cterm=italic
