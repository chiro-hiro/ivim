# Autocomplete — Design

**Date:** 2026-04-19
**Status:** Design — not yet implemented
**Scope:** Plugin-free IDE-style auto-completion for iVim, dispatching between keyword completion and filetype-specific `omnifunc` based on the character typed.

## Goal

Add a completion popup that auto-triggers as the user types, fed by two Vim built-in sources:

- **Keyword completion** (`<C-n>`) — identifiers from the current file and other open buffers.
- **Omnifunc** (`<C-x><C-o>`) — filetype-aware completion (e.g. `csscomplete`, `pythoncomplete`, `syntaxcomplete`).

Dispatch happens automatically: word characters drive keyword completion; filetype-configured trigger characters (like `.`, `::`, `->`) drive omnifunc.

## Non-Goals

- No Language Server Protocol integration.
- No snippet expansion, signature help, or hover documentation.
- No fuzzy matching or custom result ranking.
- No third-party dependencies, no plugin managers, no Lua.

These would all violate iVim's "vimscript only, no external deps" convention. Users who want LSP-grade suggestions should reach for a different distribution.

## Decisions

| # | Question                                    | Choice                                                                 |
|---|---------------------------------------------|------------------------------------------------------------------------|
| 1 | Trigger behavior                            | Auto-trigger as user types (modern IDE feel)                           |
| 2 | Popup key bindings                          | IDE-style: `<Tab>`/`<S-Tab>` navigate; `<CR>` accepts no newline; `<Esc>` dismisses + exits insert |
| 3 | Source dispatch                             | Smart: word chars → keyword, trigger chars → omnifunc                  |
| 4 | Keyword minimum prefix                      | 2 characters                                                           |
| 5 | Prose filetypes                             | Disabled in `markdown`, `gitcommit`, `text`, `help`                    |

## Architecture

### Files touched

| File                           | Change | Purpose                                                         |
|--------------------------------|--------|-----------------------------------------------------------------|
| `vimrc`                        | modify | Move `filetype plugin indent on` here (see "Load-order concern" below) |
| `plugin/settings.vim`          | modify | Remove `filetype plugin indent on` (relocated to vimrc)          |
| `plugin/autocomplete.vim`      | new    | Engine: `completeopt`, setup autocmd, trigger handler, popup-navigation keymaps |
| `after/ftplugin/c.vim`         | modify | `omnifunc` + trigger list                                        |
| `after/ftplugin/cpp.vim`       | modify | `omnifunc` + trigger list                                        |
| `after/ftplugin/css.vim`       | modify | `omnifunc` + trigger list                                        |
| `after/ftplugin/html.vim`      | modify | `omnifunc` + trigger list                                        |
| `after/ftplugin/javascript.vim`| modify | `omnifunc` + trigger list                                        |
| `after/ftplugin/typescript.vim`| modify | `omnifunc` + trigger list                                        |
| `after/ftplugin/python.vim`    | modify | `omnifunc` + trigger list (guarded by `has('python3')`)          |
| `after/ftplugin/rust.vim`      | modify | `omnifunc` + trigger list                                        |
| `after/ftplugin/lua.vim`       | modify | `omnifunc` + trigger list                                        |
| `after/ftplugin/sh.vim`        | modify | `omnifunc` + trigger list                                        |
| `after/ftplugin/dockerfile.vim`| modify | `omnifunc` only (keyword-only, no trigger chars)                 |
| `after/ftplugin/json.vim`      | modify | `omnifunc` only                                                  |
| `after/ftplugin/toml.vim`      | modify | `omnifunc` only                                                  |
| `after/ftplugin/yaml.vim`      | modify | `omnifunc` only                                                  |
| `after/ftplugin/markdown.vim`  | modify | `let b:ivim_autocomplete_disable = 1`                            |
| `CLAUDE.md`                    | modify | Document `## Autocomplete` section, feature guards, conventions  |
| `README.md`                    | modify | Add popup keys to keymaps table and a short feature blurb        |

No new ftplugin files are created for `gitcommit` / `text` / `help`. The engine handles these via a central prose-filetype dict, so we do not pay the maintenance cost of four new ftplugin files that would each contain a single line.

### Runtime architecture

```
Vim loads plugin/autocomplete.vim
    ↓
Installs FileType autocmd → s:SetupBuffer
    ↓
On each buffer's FileType event:
  - early-exit if b:ivim_autocomplete_disable = 1
  - early-exit if filetype in prose list
  - precompile b:ivim_trigger_pattern from b:ivim_complete_triggers
  - cache b:ivim_has_omnifunc = !empty(&omnifunc)
  - install <buffer>-local TextChangedI autocmd → s:MaybeTrigger
    ↓
On each insert-mode change in an active buffer:
  s:MaybeTrigger:
    - early-exit if pumvisible()
    - get last char before cursor
    - if trigger char + has omnifunc: feedkeys("<C-x><C-o>")
    - elif word char AND 2+ word chars before cursor: feedkeys("<C-n>")
    - else: no-op
    ↓
Popup appears; user navigates with <Tab>/<S-Tab>, accepts with <CR>, cancels with <Esc>
```

**Critical property:** disabled and prose buffers have no `TextChangedI` autocmd attached at all. They pay zero per-keystroke cost.

### Load-order concern

Vim fires `FileType` autocommands in *registration order* regardless of augroup. iVim currently calls `filetype plugin indent on` in `plugin/settings.vim`. Alphabetically, `plugin/autocomplete.vim` loads before `plugin/settings.vim`, so our `FileType` autocmd would register *before* Vim's built-in ftplugin loader — causing `s:SetupBuffer` to fire before any ftplugin has set `omnifunc` or `b:ivim_complete_triggers`.

**Fix:** move the single line `filetype plugin indent on` from `plugin/settings.vim` to `vimrc`, placed before the colorscheme line. This ensures ftplugin's own `FileType` autocmd is registered before any `plugin/*.vim` file loads, so our autocmd always fires *after* ftplugins have populated the buffer-local config.

No other plugin in iVim currently registers a `FileType` autocmd, so this relocation is transparent to all existing behavior.

### Buffer-local contract

Each active buffer carries:

| Variable                     | Type     | Set by            | Purpose                                              |
|------------------------------|----------|-------------------|------------------------------------------------------|
| `b:ivim_autocomplete_disable`| `0`/`1`  | ftplugin or user  | Opt-out flag; `1` prevents engine setup for buffer   |
| `b:ivim_complete_triggers`   | list     | ftplugin          | Characters that fire omnifunc dispatch               |
| `b:ivim_trigger_pattern`     | regex    | engine            | Precompiled char class from the above                |
| `b:ivim_has_omnifunc`        | `0`/`1`  | engine            | Cached `!empty(&omnifunc)` after ftplugin runs       |

`b:ivim_*` is the project convention for cross-file buffer-local state (new — document in CLAUDE.md).

## Components

### Engine (`plugin/autocomplete.vim`)

```vim
" plugin/autocomplete.vim — IDE-style auto-completion

set completeopt=menuone,noinsert,noselect
set shortmess+=c
set pumheight=10

let s:prose_filetypes = {'markdown': 1, 'gitcommit': 1, 'text': 1, 'help': 1}

function! s:SetupBuffer() abort
  if get(b:, 'ivim_autocomplete_disable', 0)    | return | endif
  if has_key(s:prose_filetypes, &filetype)      | return | endif

  let triggers = get(b:, 'ivim_complete_triggers', ['.'])
  let b:ivim_trigger_pattern =
        \ empty(triggers)
        \ ? ''
        \ : '[' . escape(join(triggers, ''), ']\^-') . ']'
  let b:ivim_has_omnifunc = !empty(&omnifunc)

  augroup ivim_autocomplete_buf
    autocmd! * <buffer>
    autocmd TextChangedI <buffer> call <SID>MaybeTrigger()
  augroup END
endfunction

function! s:MaybeTrigger() abort
  if pumvisible() | return | endif
  let col = col('.')
  if col < 2 | return | endif
  let line = getline('.')
  let ch = line[col - 2]

  if b:ivim_has_omnifunc
        \ && !empty(b:ivim_trigger_pattern)
        \ && ch =~# b:ivim_trigger_pattern
    call feedkeys("\<C-x>\<C-o>", 'n')
  elseif ch =~# '\k' && col >= 3 && line[col - 3] =~# '\k'
    call feedkeys("\<C-n>", 'n')
  endif
endfunction

augroup ivim_autocomplete
  autocmd!
  autocmd FileType * call s:SetupBuffer()
augroup END

" Popup navigation — all <expr> mappings fall through when popup not visible
inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

if has('patch-8.0.1775')
  inoremap <expr> <CR>
        \ pumvisible() && complete_info(['selected']).selected != -1
        \ ? "\<C-y>"
        \ : "\<CR>"
else
  inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<CR>"
endif

inoremap <expr> <Esc> pumvisible() ? "\<C-e>\<Esc>" : "\<Esc>"
```

### Per-filetype configuration

Each ftplugin adds two lines in the same style as existing `setlocal` entries:

```vim
" example: after/ftplugin/rust.vim adds
setlocal omnifunc=syntaxcomplete#Complete
let b:ivim_complete_triggers = ['.', ':']
```

**Full mapping:**

| ftplugin        | omnifunc                         | triggers          |
|-----------------|----------------------------------|-------------------|
| c               | `ccomplete#Complete`             | `['.', '>']`      |
| cpp             | `ccomplete#Complete`             | `['.', '>', ':']` |
| css             | `csscomplete#CompleteCSS`        | `[':']`           |
| html            | `htmlcomplete#CompleteTags`      | `['<', '/', ' ']` |
| javascript      | `javascriptcomplete#CompleteJS`  | `['.']`           |
| typescript      | `javascriptcomplete#CompleteJS`  | `['.']`           |
| python          | `python3complete#Complete`\*     | `['.']`           |
| rust            | `syntaxcomplete#Complete`        | `['.', ':']`      |
| lua             | `syntaxcomplete#Complete`        | `['.', ':']`      |
| sh              | `syntaxcomplete#Complete`        | `['$']`           |
| dockerfile      | `syntaxcomplete#Complete`        | `[]`              |
| json            | `syntaxcomplete#Complete`        | `[]`              |
| toml            | `syntaxcomplete#Complete`        | `[]`              |
| yaml            | `syntaxcomplete#Complete`        | `[]`              |
| markdown        | — (disabled)                     | —                 |

\* `python.vim` guards with `has('python3')`, falling back to `syntaxcomplete#Complete` on minimal Vim builds. No other omnifunc in the table requires a feature guard (all are pure Vimscript).

Filetypes not in the table (e.g. vim, git, diff) hit the engine's default: `b:ivim_complete_triggers` defaults to `['.']` but with `b:ivim_has_omnifunc = 0`, no omnifunc dispatch fires — only keyword completion.

## Key Bindings

All insert-mode, all context-sensitive via `pumvisible()`:

| Key      | Popup visible                                    | Popup not visible |
|----------|--------------------------------------------------|-------------------|
| `<Tab>`  | Next item (`<C-n>`)                              | Normal tab/indent |
| `<S-Tab>`| Previous item (`<C-p>`)                          | Normal `<S-Tab>`  |
| `<CR>`   | Accept selection (`<C-y>`) if one is highlighted; otherwise newline | Newline           |
| `<Esc>`  | Cancel popup (`<C-e>`) and exit insert mode      | Exit insert mode  |

`<CR>`'s "only accept if an item is selected" behavior requires Vim 8.0.1775+ (`complete_info()`). Older builds use the simpler `pumvisible() ? <C-y> : <CR>` — slightly worse (closes popup on `<CR>` with no selection) but functional.

`<C-n>`, `<C-p>`, `<C-y>`, `<C-e>` in insert mode are unchanged — power users' muscle memory works.

## Data Flow

```
User types 'f' in insert mode, buffer is Python
  ↓
TextChangedI fires → s:MaybeTrigger
  pumvisible? no
  col = 2, line = 'f', ch = 'f'
  trigger char? no (not '.')
  word char + 2+ prefix? col >= 3 is false → no-op
  ↓
User types 'o'
  ↓
TextChangedI fires → s:MaybeTrigger
  pumvisible? no
  col = 3, line = 'fo', ch = 'o'
  trigger char? no
  word char + 2+ prefix? yes (line[0]='f' is \k)
  → feedkeys("<C-n>")
  ↓
Popup shows with keyword matches for 'fo'
  ↓
User types 'o'
  ↓
TextChangedI fires → s:MaybeTrigger
  pumvisible? yes → early exit
  ↓
Vim filters existing popup to matches for 'foo'
  ↓
User presses <Tab> → <C-n> → highlights first item
User presses <CR> → complete_info selected != -1 → <C-y> → accepts
```

Same flow for omnifunc, except the dispatch feeds `<C-x><C-o>` when the last char matches `b:ivim_trigger_pattern`.

## Error Handling

- **Omnifunc returns nothing** — Vim's normal behavior: popup doesn't appear. `shortmess+=c` suppresses "Pattern not found" messages.
- **Omnifunc errors** (e.g. Python import error mid-completion) — Vim shows the error in the status line. No silencing; we want the user to see real problems.
- **Python3 omnifunc on non-python3 Vim** — guarded in `python.vim` via `has('python3')` fallback to `syntaxcomplete#Complete`.
- **`syntaxcomplete` on a buffer with no active syntax** — returns empty, no popup. Harmless.
- **Buffer switches filetype mid-session** — `FileType` autocmd re-fires; `s:SetupBuffer` either reinstalls with new values or removes autocmd on switch to prose filetype. Safe.

## Testing Plan

This project has no automated test suite; verification is manual. The implementation plan will include a manual test checklist:

1. Open `.py` file, type `fo` → keyword popup appears
2. Type `.` after a name → omnifunc popup appears
3. Open `.md` file, type `foo` → no popup
4. In any active buffer, press `<Tab>` at start of line with no popup → indents
5. Press `<CR>` with popup visible but no selection → inserts newline (requires Vim 8.0.1775+)
6. Press `<CR>` with popup visible after `<Tab>` navigation → accepts selection, no newline
7. Press `<Esc>` with popup visible → closes popup, exits insert mode
8. On a Vim built without `+python3`, open `.py` file, verify fallback to syntaxcomplete works
9. Verify `<C-n>` native keyword completion still works when manually invoked

## Risks & Mitigations

| # | Risk                                                                      | Mitigation                                                          |
|---|---------------------------------------------------------------------------|---------------------------------------------------------------------|
| 1 | Built-in `javascriptcomplete` is thin (DOM/jQuery era, no module analysis) | Documented; users who need real JS/TS intelligence need a different tool |
| 2 | `python3complete` requires `+python3`                                     | ftplugin guards with `has('python3')`, falls back to `syntaxcomplete` |
| 3 | Popup flicker during fast typing on slow terminals                        | Accepted; a debounce timer would hurt responsiveness                |
| 4 | Undo-history fragmentation from frequent `TextChangedI`                   | Not observed on Vim 8.2+; flagged for record                        |
| 5 | Stale `b:ivim_*` state after filetype change to prose                     | `s:SetupBuffer` re-fires on `FileType`; stale vars harmless without the autocmd |
| 6 | `<CR>` closes popup even with no selection on Vim <8.0.1775               | Feature guard; older Vim gets simpler fallback                      |
| 7 | `<Esc>` remapping could surprise users with unusual insert-exit habits    | Only remapped in insert mode and only active when `pumvisible()`    |

## Documentation Updates

### CLAUDE.md

- Add `## Autocomplete` section (after `## Statusline`) covering summary, key bindings table, data flow, buffer-local contract, prose-filetype list.
- Add `complete_info()` row to `## Feature Guards`: `has('patch-8.0.1775')` in autocomplete.vim.
- Add `plugin/autocomplete.vim` to project tree.
- Add `b:ivim_*` buffer-variable prefix to `## Conventions`.

### README.md

- Add popup navigation keys to the keymaps table (`<Tab>`/`<S-Tab>`/`<CR>`/`<Esc>` context-sensitive to popup).
- Short feature blurb describing auto-trigger + source dispatch.

## Implementation Sequence

To be detailed in the implementation plan, but the rough order:

1. Move `filetype plugin indent on` from `plugin/settings.vim` to `vimrc` (load-order fix).
2. Add `plugin/autocomplete.vim` (engine only, no per-filetype config yet). Verify: no regressions when opening existing filetypes.
3. Add per-filetype `omnifunc` + triggers to all 15 ftplugins, one at a time or grouped by omnifunc. Verify each with the manual test checklist.
4. Add `b:ivim_autocomplete_disable = 1` to `markdown.vim`. Verify markdown is quiet.
5. Update `CLAUDE.md` and `README.md`.
6. Final pass: manually exercise all entries in the testing plan.
