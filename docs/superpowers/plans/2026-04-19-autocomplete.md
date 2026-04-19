# Autocomplete Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add IDE-style auto-completion to iVim that dispatches between keyword completion (`<C-n>`) and filetype-specific `omnifunc` (`<C-x><C-o>`) based on the last character typed, configured per-language via existing ftplugins.

**Architecture:** One new plugin file (`plugin/autocomplete.vim`) contains the engine — `completeopt` settings, a `FileType` setup autocmd that installs buffer-local `TextChangedI` handlers only for active buffers, a trigger dispatcher that feeds either `<C-n>` or `<C-x><C-o>`, and four context-sensitive popup-navigation keymaps. Each ftplugin gets two new lines (`setlocal omnifunc=...` + `let b:ivim_complete_triggers = [...]`). Prose filetypes (markdown/gitcommit/text/help) are handled centrally via a dict — no new ftplugin files are created.

**Tech Stack:** Pure Vimscript. Targets Vim 8.0+. Uses only built-in completion APIs (`TextChangedI`, `pumvisible()`, `feedkeys()`, `complete_info()`). No plugins, no LSP, no external dependencies.

**Verification:** This project has no automated test suite. Each task includes explicit manual verification steps (open Vim, type these keys, observe this result). Regressions are caught by running the existing workflow in a real Vim session.

**Spec reference:** `docs/superpowers/specs/2026-04-19-autocomplete-design.md`

---

## File Structure

| File                            | Status   | Responsibility                                                       |
|---------------------------------|----------|----------------------------------------------------------------------|
| `vimrc`                         | modify   | Add `filetype plugin indent on` before the colorscheme line          |
| `plugin/settings.vim`           | modify   | Remove `filetype plugin indent on` (relocated to vimrc)              |
| `plugin/autocomplete.vim`       | **new**  | Engine + popup-navigation keymaps                                    |
| `after/ftplugin/c.vim`          | modify   | `omnifunc=ccomplete#Complete`, triggers `['.', '>']`                 |
| `after/ftplugin/cpp.vim`        | modify   | `omnifunc=ccomplete#Complete`, triggers `['.', '>', ':']`            |
| `after/ftplugin/css.vim`        | modify   | `omnifunc=csscomplete#CompleteCSS`, triggers `[':']`                 |
| `after/ftplugin/html.vim`       | modify   | `omnifunc=htmlcomplete#CompleteTags`, triggers `['<', '/', ' ']`     |
| `after/ftplugin/javascript.vim` | modify   | `omnifunc=javascriptcomplete#CompleteJS`, triggers `['.']`           |
| `after/ftplugin/typescript.vim` | modify   | `omnifunc=javascriptcomplete#CompleteJS`, triggers `['.']`           |
| `after/ftplugin/python.vim`     | modify   | Guarded `omnifunc`, triggers `['.']`                                 |
| `after/ftplugin/rust.vim`       | modify   | `omnifunc=syntaxcomplete#Complete`, triggers `['.', ':']`            |
| `after/ftplugin/lua.vim`        | modify   | `omnifunc=syntaxcomplete#Complete`, triggers `['.', ':']`            |
| `after/ftplugin/sh.vim`         | modify   | `omnifunc=syntaxcomplete#Complete`, triggers `['$']`                 |
| `after/ftplugin/dockerfile.vim` | modify   | `omnifunc=syntaxcomplete#Complete`, no triggers                      |
| `after/ftplugin/json.vim`       | modify   | `omnifunc=syntaxcomplete#Complete`, no triggers                      |
| `after/ftplugin/toml.vim`       | modify   | `omnifunc=syntaxcomplete#Complete`, no triggers                      |
| `after/ftplugin/yaml.vim`       | modify   | `omnifunc=syntaxcomplete#Complete`, no triggers                      |
| `after/ftplugin/markdown.vim`   | modify   | `let b:ivim_autocomplete_disable = 1`                                |
| `CLAUDE.md`                     | modify   | New `## Autocomplete` section, feature-guard row, tree update, convention |
| `README.md`                     | modify   | Popup keys + short feature blurb                                     |

---

## Task 1: Relocate `filetype plugin indent on` to vimrc

**Why:** `plugin/autocomplete.vim` (Task 2) will register a `FileType` autocmd. Vim fires `FileType` autocmds in registration order, regardless of augroup. If `filetype plugin indent on` stays in `plugin/settings.vim`, it registers Vim's ftplugin-loader autocmd *after* ours (because `autocomplete.vim` loads alphabetically before `settings.vim`), so our setup runs *before* ftplugins have set `omnifunc`. Moving the line to `vimrc` registers the ftplugin loader before any `plugin/*.vim` file runs.

**Files:**
- Modify: `/home/parallels/development/ivim/vimrc`
- Modify: `/home/parallels/development/ivim/plugin/settings.vim:15`

- [ ] **Step 1: Update vimrc**

Replace the current contents of `vimrc` with:

```vim
" iVim - Plugin-free Vim configuration
" https://github.com/chiro-hiro/ivim

" Encoding
set encoding=utf-8
scriptencoding utf-8

" Leader key - must be set before any mappings
let mapleader = ' '
let maplocalleader = ' '

" Filetype plugin + indent - must be enabled before plugin/ files load
" so that our FileType autocmds run after Vim's built-in ftplugin loader
filetype plugin indent on

" Colorscheme
colorscheme tokyonight
```

- [ ] **Step 2: Remove the line from settings.vim**

Open `plugin/settings.vim` and delete the line `filetype plugin indent on` (currently line 15, between `syntax on` and `set nowrap`). The resulting block should read:

```vim
set background=dark
syntax on
set nowrap
```

- [ ] **Step 3: Verify ftplugins still load**

Run:

```bash
vim -c 'e after/ftplugin/python.vim' -c 'set filetype?' -c 'qa' 2>&1
```

Then open Vim on any Python file and check:

```bash
cd /home/parallels/development/ivim
echo 'x = 1' > /tmp/a.py
vim /tmp/a.py -c 'echo "ts=".&tabstop' -c 'qa'
rm /tmp/a.py
```

Expected: `ts=4` appears (i.e., `after/ftplugin/python.vim` still sets `tabstop=4`).

- [ ] **Step 4: Commit**

```bash
cd /home/parallels/development/ivim
git add vimrc plugin/settings.vim
git commit -m "$(cat <<'EOF'
Move filetype plugin indent on from settings.vim to vimrc

Needed so built-in ftplugin FileType autocmd registers before any
plugin/*.vim registers its own, ensuring our future autocomplete
setup runs after ftplugins have configured buffer-local state.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Create autocomplete engine (trigger dispatch)

**Files:**
- Create: `/home/parallels/development/ivim/plugin/autocomplete.vim`

- [ ] **Step 1: Create the engine file**

Write the following exact content to `plugin/autocomplete.vim`:

```vim
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
  if get(b:, 'ivim_autocomplete_disable', 0)    | return | endif
  if has_key(s:prose_filetypes, &filetype)      | return | endif

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
  if pumvisible() | return | endif
  let l:col = col('.')
  if l:col < 2 | return | endif
  let l:line = getline('.')
  let l:ch = l:line[l:col - 2]

  if b:ivim_has_omnifunc
        \ && !empty(b:ivim_trigger_pattern)
        \ && l:ch =~# b:ivim_trigger_pattern
    call feedkeys("\<C-x>\<C-o>", 'n')
  elseif l:ch =~# '\k' && l:col >= 3 && l:line[l:col - 3] =~# '\k'
    call feedkeys("\<C-n>", 'n')
  endif
endfunction

augroup ivim_autocomplete
  autocmd!
  autocmd FileType * call s:SetupBuffer()
augroup END
```

- [ ] **Step 2: Verify the file has no syntax errors**

Run:

```bash
cd /home/parallels/development/ivim
vim -u NONE -U NONE -N -c 'source plugin/autocomplete.vim' -c 'echo "ok"' -c 'qa' 2>&1
```

Expected: prints `ok` with no error messages. Any `E4xx:` error means there's a typo.

- [ ] **Step 3: Verify autocomplete is wired but inert (no ftplugin config yet)**

Create a scratch buffer and confirm the engine activates without errors:

```bash
cd /home/parallels/development/ivim
cat > /tmp/verify.sh <<'SH'
echo 'x = 1' > /tmp/a.py
vim /tmp/a.py -c 'autocmd TextChangedI *' -c 'echo get(b:, "ivim_has_omnifunc", "unset")' -c 'qa'
SH
bash /tmp/verify.sh
rm -f /tmp/a.py /tmp/verify.sh
```

Expected: output includes `ivim_autocomplete_buf` autocmd for `*.py` buffer, and `0` (because Python ftplugin hasn't been configured yet — no omnifunc set). No error messages.

- [ ] **Step 4: Commit**

```bash
cd /home/parallels/development/ivim
git add plugin/autocomplete.vim
git commit -m "$(cat <<'EOF'
Add autocomplete engine (trigger dispatch only)

Installs a FileType autocmd that precompiles per-buffer trigger
patterns and wires a buffer-local TextChangedI handler. Prose
filetypes and disabled buffers get no autocmd attached.

Keymaps and per-filetype omnifunc/triggers come in follow-ups.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add popup-navigation keymaps

**Files:**
- Modify: `/home/parallels/development/ivim/plugin/autocomplete.vim` (append)

- [ ] **Step 1: Append keymaps to the engine file**

Append the following to `plugin/autocomplete.vim`:

```vim

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
```

- [ ] **Step 2: Verify keymaps exist and are context-sensitive**

```bash
cd /home/parallels/development/ivim
vim -c 'verbose imap <Tab>' -c 'qa' 2>&1 | head -20
```

Expected: the `<Tab>` insert-mode mapping exists and its RHS contains `pumvisible()`. Same for `<S-Tab>`, `<CR>`, `<Esc>`.

- [ ] **Step 3: Manual interactive verification**

Run these steps manually in a real Vim session (automated is unreliable for insert mode + popup interaction):

```bash
cd /home/parallels/development/ivim
echo -e 'foobar\nfoo\nbaz' > /tmp/a.txt
vim /tmp/a.txt
```

Inside Vim:
1. Press `G` then `o` to open a new line in insert mode.
2. Press `Ctrl-n` to manually trigger keyword completion. A popup with `foobar`, `foo`, `baz` should appear, with **no item pre-highlighted** (because `noselect`).
3. Press `<Tab>` — first item highlights.
4. Press `<S-Tab>` — highlight moves back / disappears.
5. Press `<Tab>` again, then `<CR>` — the selected text is inserted, **no newline added**.
6. Undo (`u`), press `<Ctrl-n>`, then press `<CR>` *without* navigating — expected: a newline is inserted and popup closes (no item accepted), because `complete_info().selected == -1`.
7. Press `Ctrl-n` again, then `<Esc>` — popup dismisses and you exit insert mode.
8. Press `i` (insert), then `<Tab>` at the start of a line — **this should insert a tab**, not navigate a popup, because no popup is visible.

Clean up:

```bash
rm /tmp/a.txt
```

- [ ] **Step 4: Commit**

```bash
cd /home/parallels/development/ivim
git add plugin/autocomplete.vim
git commit -m "$(cat <<'EOF'
Add context-sensitive popup-navigation keymaps

Tab/S-Tab navigate the popup when visible, CR accepts only when an
item is selected (guarded by has('patch-8.0.1775')), Esc closes the
popup and exits insert. All <expr> so they fall through to normal
behavior when no popup is showing.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Configure Python ftplugin (with python3 guard)

**Files:**
- Modify: `/home/parallels/development/ivim/after/ftplugin/python.vim`

- [ ] **Step 1: Replace the file contents**

Overwrite `after/ftplugin/python.vim` with:

```vim
setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
setlocal textwidth=88
setlocal colorcolumn=88

if has('python3')
  setlocal omnifunc=python3complete#Complete
else
  setlocal omnifunc=syntaxcomplete#Complete
endif
let b:ivim_complete_triggers = ['.']
```

- [ ] **Step 2: Verify omnifunc and triggers are set**

```bash
cd /home/parallels/development/ivim
echo 'import os' > /tmp/a.py
vim /tmp/a.py \
  -c 'echo "omnifunc=" . &omnifunc' \
  -c 'echo "triggers=" . string(b:ivim_complete_triggers)' \
  -c 'echo "pattern=" . b:ivim_trigger_pattern' \
  -c 'qa'
rm /tmp/a.py
```

Expected (on a Vim with +python3):
```
omnifunc=python3complete#Complete
triggers=['.']
pattern=[.]
```

On a Vim without +python3, `omnifunc=syntaxcomplete#Complete` instead.

- [ ] **Step 3: Manual interactive verification**

```bash
cd /home/parallels/development/ivim
cat > /tmp/a.py <<'PY'
import os

def hello():
    pass

hel
PY
vim /tmp/a.py
```

Inside Vim:
1. Press `G` then `A` to append at end of last line `hel`.
2. Type another character: `l`. The word is now `hell` (4 chars); expected: a popup appears suggesting `hello`.
3. Press `<Esc>` to dismiss, then `A` on line 1 at the end (after `import os`), type `.`: expected: omnifunc popup with `os` module members (path, environ, getcwd, etc.).
4. `:q!` to quit without saving.

Clean up:

```bash
rm /tmp/a.py
```

- [ ] **Step 4: Commit**

```bash
cd /home/parallels/development/ivim
git add after/ftplugin/python.vim
git commit -m "$(cat <<'EOF'
Configure autocomplete for Python

python3complete on builds with +python3, syntaxcomplete fallback
otherwise. Trigger on . for attribute access.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Configure C and C++ ftplugins

**Files:**
- Modify: `/home/parallels/development/ivim/after/ftplugin/c.vim`
- Modify: `/home/parallels/development/ivim/after/ftplugin/cpp.vim`

- [ ] **Step 1: Replace `c.vim` contents**

Overwrite `after/ftplugin/c.vim` with:

```vim
setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
setlocal cinoptions=l1,g0,:0

setlocal omnifunc=ccomplete#Complete
let b:ivim_complete_triggers = ['.', '>']
```

- [ ] **Step 2: Replace `cpp.vim` contents**

Overwrite `after/ftplugin/cpp.vim` with:

```vim
setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
setlocal cinoptions=l1,g0,:0

setlocal omnifunc=ccomplete#Complete
let b:ivim_complete_triggers = ['.', '>', ':']
```

- [ ] **Step 3: Verify config is loaded**

```bash
cd /home/parallels/development/ivim
echo 'int main(void) { return 0; }' > /tmp/a.c
vim /tmp/a.c \
  -c 'echo "c omnifunc=" . &omnifunc' \
  -c 'echo "c pattern=" . b:ivim_trigger_pattern' \
  -c 'qa'
echo 'int main() { return 0; }' > /tmp/a.cpp
vim /tmp/a.cpp \
  -c 'echo "cpp omnifunc=" . &omnifunc' \
  -c 'echo "cpp pattern=" . b:ivim_trigger_pattern' \
  -c 'qa'
rm /tmp/a.c /tmp/a.cpp
```

Expected:
```
c omnifunc=ccomplete#Complete
c pattern=[.>]
cpp omnifunc=ccomplete#Complete
cpp pattern=[.>:]
```

- [ ] **Step 4: Manual interactive verification**

```bash
echo 'int main(void) { return 0; }' > /tmp/a.c
cd /home/parallels/development/ivim && vim /tmp/a.c
```

Inside Vim:
1. `G` then `o` to open a new line in insert mode.
2. Type `int var = ma` — 2 chars typed after `ma` is `a`; after typing the second char of a word the popup should appear. After typing `ma`, popup appears with `main` suggestion (keyword completion from current buffer).
3. Press `<Esc>`, `:q!` to quit.

Clean up:

```bash
rm /tmp/a.c
```

- [ ] **Step 5: Commit**

```bash
cd /home/parallels/development/ivim
git add after/ftplugin/c.vim after/ftplugin/cpp.vim
git commit -m "$(cat <<'EOF'
Configure autocomplete for C and C++

ccomplete uses ctags when available; trigger chars support member
access (. and ->) plus C++ namespace scope (::).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Configure HTML and CSS ftplugins

**Files:**
- Modify: `/home/parallels/development/ivim/after/ftplugin/html.vim`
- Modify: `/home/parallels/development/ivim/after/ftplugin/css.vim`

- [ ] **Step 1: Replace `html.vim` contents**

Overwrite `after/ftplugin/html.vim` with:

```vim
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab

setlocal omnifunc=htmlcomplete#CompleteTags
let b:ivim_complete_triggers = ['<', '/', ' ']
```

- [ ] **Step 2: Replace `css.vim` contents**

Overwrite `after/ftplugin/css.vim` with:

```vim
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab

setlocal omnifunc=csscomplete#CompleteCSS
let b:ivim_complete_triggers = [':']
```

- [ ] **Step 3: Verify config is loaded**

```bash
cd /home/parallels/development/ivim
echo '<html></html>' > /tmp/a.html
vim /tmp/a.html \
  -c 'echo "html omnifunc=" . &omnifunc' \
  -c 'echo "html pattern=" . b:ivim_trigger_pattern' \
  -c 'qa'
echo 'body { color: red; }' > /tmp/a.css
vim /tmp/a.css \
  -c 'echo "css omnifunc=" . &omnifunc' \
  -c 'echo "css pattern=" . b:ivim_trigger_pattern' \
  -c 'qa'
rm /tmp/a.html /tmp/a.css
```

Expected:
```
html omnifunc=htmlcomplete#CompleteTags
html pattern=[</ ]
css omnifunc=csscomplete#CompleteCSS
css pattern=[:]
```

- [ ] **Step 4: Manual interactive verification**

```bash
echo '' > /tmp/a.html
cd /home/parallels/development/ivim && vim /tmp/a.html
```

Inside Vim:
1. Press `i` to enter insert mode.
2. Type `<` — popup should appear with HTML tag names (html, head, body, div, etc.).
3. Press `<Esc>`, `:q!`.

Then:

```bash
echo 'body {}' > /tmp/a.css
cd /home/parallels/development/ivim && vim /tmp/a.css
```

Inside Vim:
1. Position cursor inside `{}` braces.
2. Enter insert mode, type `color` then `:` then space — popup should appear with CSS color values (red, blue, rgba, etc.).
3. `:q!` to quit.

Clean up:

```bash
rm /tmp/a.html /tmp/a.css
```

- [ ] **Step 5: Commit**

```bash
cd /home/parallels/development/ivim
git add after/ftplugin/html.vim after/ftplugin/css.vim
git commit -m "$(cat <<'EOF'
Configure autocomplete for HTML and CSS

htmlcomplete triggers on <, /, and space (for attribute names inside
tags). csscomplete triggers on : for property values.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Configure JavaScript and TypeScript ftplugins

**Files:**
- Modify: `/home/parallels/development/ivim/after/ftplugin/javascript.vim`
- Modify: `/home/parallels/development/ivim/after/ftplugin/typescript.vim`

- [ ] **Step 1: Replace `javascript.vim` contents**

Overwrite `after/ftplugin/javascript.vim` with:

```vim
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab

setlocal omnifunc=javascriptcomplete#CompleteJS
let b:ivim_complete_triggers = ['.']
```

- [ ] **Step 2: Replace `typescript.vim` contents**

Overwrite `after/ftplugin/typescript.vim` with:

```vim
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab

setlocal omnifunc=javascriptcomplete#CompleteJS
let b:ivim_complete_triggers = ['.']
```

- [ ] **Step 3: Verify config is loaded**

```bash
cd /home/parallels/development/ivim
echo 'const x = 1;' > /tmp/a.js
vim /tmp/a.js \
  -c 'echo "js omnifunc=" . &omnifunc' \
  -c 'echo "js pattern=" . b:ivim_trigger_pattern' \
  -c 'qa'
echo 'const x: number = 1;' > /tmp/a.ts
vim /tmp/a.ts \
  -c 'echo "ts omnifunc=" . &omnifunc' \
  -c 'echo "ts pattern=" . b:ivim_trigger_pattern' \
  -c 'qa'
rm /tmp/a.js /tmp/a.ts
```

Expected:
```
js omnifunc=javascriptcomplete#CompleteJS
js pattern=[.]
ts omnifunc=javascriptcomplete#CompleteJS
ts pattern=[.]
```

- [ ] **Step 4: Manual interactive verification**

```bash
cat > /tmp/a.js <<'JS'
const someVariable = 42;
const another = someVa
JS
cd /home/parallels/development/ivim && vim /tmp/a.js
```

Inside Vim:
1. Press `G$` to jump to end of last line.
2. Press `a` to append (cursor after `someVa`).
3. Type `r` — popup appears with `someVariable` (keyword completion from buffer).
4. `:q!` to quit.

Clean up:

```bash
rm /tmp/a.js
```

- [ ] **Step 5: Commit**

```bash
cd /home/parallels/development/ivim
git add after/ftplugin/javascript.vim after/ftplugin/typescript.vim
git commit -m "$(cat <<'EOF'
Configure autocomplete for JavaScript and TypeScript

Both use javascriptcomplete (Vim's built-in) — limited DOM-era
dictionary; real TS intelligence needs a language server we don't
ship. Keyword completion from buffer picks up identifiers.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Configure Rust and Lua ftplugins

**Files:**
- Modify: `/home/parallels/development/ivim/after/ftplugin/rust.vim`
- Modify: `/home/parallels/development/ivim/after/ftplugin/lua.vim`

- [ ] **Step 1: Replace `rust.vim` contents**

Overwrite `after/ftplugin/rust.vim` with:

```vim
setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
setlocal textwidth=100
setlocal colorcolumn=100

setlocal omnifunc=syntaxcomplete#Complete
let b:ivim_complete_triggers = ['.', ':']
```

- [ ] **Step 2: Replace `lua.vim` contents**

Overwrite `after/ftplugin/lua.vim` with:

```vim
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab

setlocal omnifunc=syntaxcomplete#Complete
let b:ivim_complete_triggers = ['.', ':']
```

- [ ] **Step 3: Verify config is loaded**

```bash
cd /home/parallels/development/ivim
echo 'fn main() {}' > /tmp/a.rs
vim /tmp/a.rs \
  -c 'echo "rust omnifunc=" . &omnifunc' \
  -c 'echo "rust pattern=" . b:ivim_trigger_pattern' \
  -c 'qa'
echo 'local x = 1' > /tmp/a.lua
vim /tmp/a.lua \
  -c 'echo "lua omnifunc=" . &omnifunc' \
  -c 'echo "lua pattern=" . b:ivim_trigger_pattern' \
  -c 'qa'
rm /tmp/a.rs /tmp/a.lua
```

Expected:
```
rust omnifunc=syntaxcomplete#Complete
rust pattern=[.:]
lua omnifunc=syntaxcomplete#Complete
lua pattern=[.:]
```

- [ ] **Step 4: Manual interactive verification**

```bash
cat > /tmp/a.rs <<'RS'
fn helper() {}

fn main() {
    hel
}
RS
cd /home/parallels/development/ivim && vim /tmp/a.rs
```

Inside Vim:
1. Position on the `hel` line, enter insert mode at end.
2. Type `p` — popup appears with `helper` from the buffer.
3. `:q!` to quit.

Clean up:

```bash
rm /tmp/a.rs
```

- [ ] **Step 5: Commit**

```bash
cd /home/parallels/development/ivim
git add after/ftplugin/rust.vim after/ftplugin/lua.vim
git commit -m "$(cat <<'EOF'
Configure autocomplete for Rust and Lua

syntaxcomplete provides language keywords from the syntax file (fn,
impl, match for Rust; local, function for Lua). Triggers on . and :
for method calls.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Configure sh, dockerfile, json, toml, yaml ftplugins

**Files:**
- Modify: `/home/parallels/development/ivim/after/ftplugin/sh.vim`
- Modify: `/home/parallels/development/ivim/after/ftplugin/dockerfile.vim`
- Modify: `/home/parallels/development/ivim/after/ftplugin/json.vim`
- Modify: `/home/parallels/development/ivim/after/ftplugin/toml.vim`
- Modify: `/home/parallels/development/ivim/after/ftplugin/yaml.vim`

- [ ] **Step 1: Replace `sh.vim` contents**

Overwrite `after/ftplugin/sh.vim` with:

```vim
setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab

setlocal omnifunc=syntaxcomplete#Complete
let b:ivim_complete_triggers = ['$']
```

- [ ] **Step 2: Replace `dockerfile.vim` contents**

Overwrite `after/ftplugin/dockerfile.vim` with:

```vim
setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab

setlocal omnifunc=syntaxcomplete#Complete
let b:ivim_complete_triggers = []
```

- [ ] **Step 3: Replace `json.vim` contents**

Overwrite `after/ftplugin/json.vim` with:

```vim
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab

setlocal omnifunc=syntaxcomplete#Complete
let b:ivim_complete_triggers = []
```

- [ ] **Step 4: Replace `toml.vim` contents**

Overwrite `after/ftplugin/toml.vim` with:

```vim
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab

setlocal omnifunc=syntaxcomplete#Complete
let b:ivim_complete_triggers = []
```

- [ ] **Step 5: Replace `yaml.vim` contents**

Overwrite `after/ftplugin/yaml.vim` with:

```vim
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab

setlocal omnifunc=syntaxcomplete#Complete
let b:ivim_complete_triggers = []
```

- [ ] **Step 6: Verify configs are loaded**

```bash
cd /home/parallels/development/ivim
for f in "a.sh:sh" "Dockerfile:dockerfile" "a.json:json" "a.toml:toml" "a.yaml:yaml"; do
  fname=${f%:*}
  echo '# test' > /tmp/$fname
  vim /tmp/$fname \
    -c 'echo &filetype . " omnifunc=" . &omnifunc . " pattern=" . b:ivim_trigger_pattern' \
    -c 'qa'
  rm /tmp/$fname
done
```

Expected:
```
sh omnifunc=syntaxcomplete#Complete pattern=[$]
dockerfile omnifunc=syntaxcomplete#Complete pattern=
json omnifunc=syntaxcomplete#Complete pattern=
toml omnifunc=syntaxcomplete#Complete pattern=
yaml omnifunc=syntaxcomplete#Complete pattern=
```

(The empty `pattern=` entries are correct — these filetypes have no trigger chars, so only keyword completion fires.)

- [ ] **Step 7: Manual interactive verification**

```bash
cat > /tmp/Dockerfile <<'DF'
FROM alpine

FR
DF
cd /home/parallels/development/ivim && vim /tmp/Dockerfile
```

Inside Vim:
1. Position on the `FR` line, enter insert mode at end.
2. Type `O` — popup appears with `FROM` suggestion (from syntax keywords or buffer).
3. `:q!` to quit.

Clean up:

```bash
rm /tmp/Dockerfile
```

- [ ] **Step 8: Commit**

```bash
cd /home/parallels/development/ivim
git add after/ftplugin/sh.vim after/ftplugin/dockerfile.vim after/ftplugin/json.vim after/ftplugin/toml.vim after/ftplugin/yaml.vim
git commit -m "$(cat <<'EOF'
Configure autocomplete for sh/dockerfile/json/toml/yaml

syntaxcomplete draws language keywords from the syntax file. sh adds
$ as a trigger for variable expansion; the structured-data filetypes
get no trigger chars — keyword completion only.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Disable autocomplete in Markdown

**Files:**
- Modify: `/home/parallels/development/ivim/after/ftplugin/markdown.vim`

- [ ] **Step 1: Replace `markdown.vim` contents**

Overwrite `after/ftplugin/markdown.vim` with:

```vim
setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
setlocal wrap
setlocal linebreak

let b:ivim_autocomplete_disable = 1
```

Note: the engine's `s:prose_filetypes` dict already contains `markdown`, so this flag is technically redundant for the default filetype. It's set anyway for two reasons: (1) consistency — a glance at the ftplugin makes the intent explicit, and (2) it covers the edge case where a markdown buffer has its filetype changed to something non-prose (the flag persists across filetype changes; the central dict check fires only on the current filetype).

- [ ] **Step 2: Verify markdown has no TextChangedI autocmd**

```bash
cd /home/parallels/development/ivim
echo '# hello' > /tmp/a.md
vim /tmp/a.md \
  -c 'redir => g:out' \
  -c 'silent autocmd TextChangedI <buffer>' \
  -c 'redir END' \
  -c 'echo "disable=" . get(b:, "ivim_autocomplete_disable", "unset")' \
  -c 'echo "autocmds=" . substitute(g:out, "\n", " | ", "g")' \
  -c 'qa'
rm /tmp/a.md
```

Expected:
```
disable=1
autocmds= | --- Autocommands --- |
```

(i.e., the autocommand list for `<buffer>` `TextChangedI` is empty — no ivim_autocomplete_buf autocmd was installed.)

- [ ] **Step 3: Manual interactive verification**

```bash
echo '# Some heading' > /tmp/a.md
cd /home/parallels/development/ivim && vim /tmp/a.md
```

Inside Vim:
1. Press `G` then `o` to open a new line in insert mode.
2. Type `hello world this is a sentence` — **no popup** should appear at any point.
3. `:q!` to quit.

Clean up:

```bash
rm /tmp/a.md
```

- [ ] **Step 4: Commit**

```bash
cd /home/parallels/development/ivim
git add after/ftplugin/markdown.vim
git commit -m "$(cat <<'EOF'
Disable autocomplete in markdown buffers

Sets b:ivim_autocomplete_disable = 1. Markdown is already in the
engine's central prose list but the explicit flag makes intent
visible at the ftplugin level.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: Update CLAUDE.md

**Files:**
- Modify: `/home/parallels/development/ivim/CLAUDE.md`

- [ ] **Step 1: Add `plugin/autocomplete.vim` to the project tree**

In the "Project Structure" section, find the `plugin/` subtree and add `autocomplete.vim` as the first entry (alphabetically):

Find:
```
├── plugin/
│   ├── settings.vim          # Core editor settings with feature guards
│   ├── keymaps.vim           # Key mappings (Space leader), terminal, search
│   ├── statusline.vim        # Custom statusline + tabline with mode colors
│   └── startscreen.vim       # Start screen with keymap help on empty Vim launch
```

Replace with:
```
├── plugin/
│   ├── autocomplete.vim      # IDE-style auto-completion engine + popup keymaps
│   ├── keymaps.vim           # Key mappings (Space leader), terminal, search
│   ├── settings.vim          # Core editor settings with feature guards
│   ├── startscreen.vim       # Start screen with keymap help on empty Vim launch
│   └── statusline.vim        # Custom statusline + tabline with mode colors
```

(Also reorders the existing entries to true alphabetical order, matching `ls` output.)

- [ ] **Step 2: Update the plugin load-order note in the Architecture section**

Find:
```
- `plugin/` files load alphabetically: keymaps.vim, settings.vim, startscreen.vim, statusline.vim
- `vimrc` runs first: sets `encoding=utf-8`, `scriptencoding utf-8`, `mapleader`/`maplocalleader` (both Space), then loads colorscheme
```

Replace with:
```
- `plugin/` files load alphabetically: autocomplete.vim, keymaps.vim, settings.vim, startscreen.vim, statusline.vim
- `vimrc` runs first: sets `encoding=utf-8`, `scriptencoding utf-8`, `mapleader`/`maplocalleader` (both Space), enables `filetype plugin indent on` (must precede plugin/ so ftplugin's FileType autocmd registers first), then loads colorscheme
```

- [ ] **Step 3: Add `complete_info()` to the Feature Guards table**

Find the Feature Guards table and add a row above the `%{%...%}` row:

```
| `complete_info()`        | `has('patch-8.0.1775')`                         | autocomplete.vim |
```

- [ ] **Step 4: Add a new `## Autocomplete` section**

Insert this section between `## Statusline` and `## Netrw File Explorer`:

```markdown
## Autocomplete

IDE-style auto-completion via `plugin/autocomplete.vim`. As you type in insert mode, a popup appears automatically: word characters (≥2 prefix) trigger keyword completion (`<C-n>`) from the current file and other open buffers; filetype-configured trigger characters (`.`, `::`, `->`, etc.) trigger `omnifunc` (`<C-x><C-o>`). Disabled in prose filetypes (markdown, gitcommit, text, help) — those buffers get no `TextChangedI` autocmd attached at all.

### Popup navigation

| Key      | Popup visible                                    | Popup not visible |
|----------|--------------------------------------------------|-------------------|
| `<Tab>`  | Next item                                        | Tab/indent        |
| `<S-Tab>`| Previous item                                    | Normal `<S-Tab>`  |
| `<CR>`   | Accept selection (only if item highlighted)      | Newline           |
| `<Esc>`  | Cancel popup and exit insert mode                | Exit insert mode  |

All four are `<expr>` mappings guarded by `pumvisible()`; when no popup is up, original behavior is preserved.

### Buffer-local contract

Any ftplugin can influence the engine by setting these before `FileType` fires:

| Variable                      | Purpose                                              |
|-------------------------------|------------------------------------------------------|
| `b:ivim_autocomplete_disable` | Set to `1` to skip the engine entirely for the buffer |
| `b:ivim_complete_triggers`    | List of characters that fire omnifunc dispatch (default `['.']`; empty list = keyword-only) |

The engine caches `b:ivim_trigger_pattern` (precompiled regex class) and `b:ivim_has_omnifunc` (cached `!empty(&omnifunc)`) on `FileType` so the per-keystroke hot path does minimal work.

### Omnifunc mapping

| Filetype group                                        | omnifunc                         |
|-------------------------------------------------------|----------------------------------|
| python                                                | `python3complete#Complete` (fallback to `syntaxcomplete#Complete` if no `+python3`) |
| c, cpp                                                | `ccomplete#Complete`             |
| javascript, typescript                                | `javascriptcomplete#CompleteJS`  |
| css                                                   | `csscomplete#CompleteCSS`        |
| html                                                  | `htmlcomplete#CompleteTags`      |
| rust, lua, sh, dockerfile, json, toml, yaml           | `syntaxcomplete#Complete`        |
| markdown                                              | — (disabled)                     |
```

- [ ] **Step 5: Add `b:ivim_*` convention note**

In the `## Conventions` section, find:
```
- Script-local functions use `s:` prefix; global functions use topic prefixes: `Stl` (statusline), `Ivim` (everything else)
```

Append immediately after:
```
- Cross-file buffer-local state uses `b:ivim_*` prefix (e.g. `b:ivim_complete_triggers`, `b:ivim_git_branch`)
```

- [ ] **Step 6: Verify the document is well-formed**

```bash
cd /home/parallels/development/ivim
grep -c '^## ' CLAUDE.md
```

Expected: at least 10 (previous count + 1 new Autocomplete section).

```bash
grep '^##' CLAUDE.md
```

Expected list includes `## Autocomplete` between `## Statusline` and `## Netrw File Explorer`.

- [ ] **Step 7: Commit**

```bash
cd /home/parallels/development/ivim
git add CLAUDE.md
git commit -m "$(cat <<'EOF'
Document autocomplete feature in CLAUDE.md

Adds ## Autocomplete section with popup keys, buffer-local contract,
and omnifunc mapping. Adds complete_info() feature guard row.
Documents b:ivim_* buffer-variable convention.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: Update README.md

**Files:**
- Modify: `/home/parallels/development/ivim/README.md`

- [ ] **Step 1: Add popup keys section to the Key Mappings area**

Find the "### Other" subsection:
```markdown
### Other

| Key | Action |
|-----|--------|
| `Space a` | Select all |
```

Insert a new subsection immediately before it:
```markdown
### Autocomplete (popup menu)

Popup appears automatically in code buffers as you type; these keys take effect only when the popup is visible, otherwise behave normally.

| Key | Action |
|-----|--------|
| `Tab` | Next completion item |
| `Shift-Tab` | Previous completion item |
| `Enter` | Accept selection (no newline inserted) |
| `Esc` | Cancel popup and exit insert mode |

```

- [ ] **Step 2: Add a Features entry for autocomplete**

Find the "### Filetype Support" subsection (under `## Features`):
```markdown
### Filetype Support
```

Insert a new subsection immediately before it:
```markdown
### Autocomplete

IDE-style auto-completion with zero plugins. Typing 2+ identifier characters pops up a keyword-completion menu from the current file and open buffers; language trigger characters (`.`, `::`, `->`, `<`, `:`, `$`) invoke Vim's built-in filetype `omnifunc`. Disabled automatically in prose filetypes (markdown, gitcommit, plain text, help).

```

- [ ] **Step 3: Update the filetype count**

Find:
```
Sensible defaults for 13 languages:
```

Replace with:
```
Sensible defaults for 15 languages:
```

Also add `Dockerfile` and `TOML` to the filetype indent table. Find:
```markdown
| 2-space indent | 4-space indent |
|---------------|---------------|
| JavaScript | Python (tw=88) |
| TypeScript | C (cinoptions) |
| HTML | C++ (cinoptions) |
| CSS | Rust (tw=100) |
| JSON | Shell |
| YAML | |
| Lua | |
| Markdown (wrap, linebreak) | |
```

Replace with:
```markdown
| 2-space indent | 4-space indent |
|---------------|---------------|
| JavaScript | Python (tw=88) |
| TypeScript | C (cinoptions) |
| HTML | C++ (cinoptions) |
| CSS | Rust (tw=100) |
| JSON | Shell |
| YAML | Dockerfile |
| Lua | |
| TOML | |
| Markdown (wrap, linebreak) | |
```

- [ ] **Step 4a: Update the `plugin/` subtree in the project structure**

Find the existing `plugin/` block:
```
├── plugin/
│   ├── settings.vim          # Core editor settings with feature guards
│   ├── keymaps.vim           # Key mappings, terminal, file explorer logic
│   ├── statusline.vim        # Statusline, tabline, git branch caching
│   └── startscreen.vim       # Start screen with keymap reference
```

Replace with:
```
├── plugin/
│   ├── autocomplete.vim      # IDE-style auto-completion engine
│   ├── keymaps.vim           # Key mappings, terminal, file explorer logic
│   ├── settings.vim          # Core editor settings with feature guards
│   ├── startscreen.vim       # Start screen with keymap reference
│   └── statusline.vim        # Statusline, tabline, git branch caching
```

(Adds `autocomplete.vim` and reorders all entries alphabetically.)

- [ ] **Step 4b: Update the ftplugin count**

Find:
```
├── after/ftplugin/           # Per-language overrides (13 filetypes + netrw)
```

Replace with:
```
├── after/ftplugin/           # Per-language overrides (15 filetypes + netrw)
```

- [ ] **Step 5: Verify changes**

```bash
cd /home/parallels/development/ivim
grep -A1 '### Autocomplete' README.md | head -5
grep '15 filetypes' README.md
grep '15 languages' README.md
```

Expected: all three grep commands produce output.

- [ ] **Step 6: Commit**

```bash
cd /home/parallels/development/ivim
git add README.md
git commit -m "$(cat <<'EOF'
Document autocomplete feature in README

Adds popup-menu keymaps under Key Mappings, Autocomplete subsection
under Features, and updates filetype count (13 -> 15, adding
Dockerfile and TOML which were previously undocumented).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: End-to-end verification

**Files:** none (verification only)

- [ ] **Step 1: Run the full manual test checklist from the spec**

Open a real Vim session and walk through each of the nine scenarios:

1. **Python keyword popup:**
   ```bash
   echo -e 'import os\n\nfoobar = 1\n' > /tmp/t.py
   cd /home/parallels/development/ivim && vim /tmp/t.py
   ```
   In Vim: `G o foo` → expect popup with `foobar`.

2. **Python omnifunc popup:**
   Same file. Type `os.` at the end of the last non-empty line → expect popup with os module members (only if `+python3`).

3. **Markdown: no popup:**
   ```bash
   echo '# test' > /tmp/t.md
   vim /tmp/t.md
   ```
   Type several words in insert mode → **no popup** at any point.

4. **Tab indents when no popup:**
   In any code buffer, press `<Tab>` at the start of an empty line in insert mode → inserts a tab/indent; no popup-navigation behavior.

5. **CR inserts newline when no selection (Vim 8.0.1775+):**
   Trigger popup with `<C-n>`. Press `<CR>` without pressing `<Tab>` first → newline inserted, popup closes. Verify by checking `:echo has('patch-8.0.1775')` returns `1` before relying on this behavior.

6. **CR accepts after Tab selection:**
   Trigger popup, press `<Tab>` to select first item, press `<CR>` → selected item inserted, no newline.

7. **Esc closes popup and exits insert:**
   Trigger popup, press `<Esc>` → popup closes, mode is Normal.

8. **Python fallback on non-python3 Vim:**
   Only if you have access to a Vim built without `+python3`:
   ```bash
   vim --version | grep python3
   ```
   If you see `-python3`, open a `.py` file and verify `:set omnifunc?` returns `syntaxcomplete#Complete`, not `python3complete#Complete`.

9. **Native `<C-n>` keyword completion still works:**
   In any active buffer, manually press `<C-n>` in insert mode → popup appears. Our auto-trigger doesn't break manual invocation.

Clean up:
```bash
rm -f /tmp/t.py /tmp/t.md
```

- [ ] **Step 2: Check the commit log**

```bash
cd /home/parallels/development/ivim
git log --oneline master.. 2>/dev/null || git log --oneline -20
```

Expected: 12 commits with clear, feature-named messages (Tasks 1 through 12).

- [ ] **Step 3: Final confirmation**

Report to the user which of the nine scenarios passed, and flag any that didn't. If any failed, investigate the root cause rather than patching the symptom — the engine is intentionally small; a failure indicates a real issue.

No commit for this task — it's verification only.

---

## Done-When

- All 13 tasks' checkboxes checked.
- Every ftplugin modification committed separately.
- `vim -u NONE -U NONE -N` loads the full config without errors.
- The nine scenarios from Task 13 all behave as expected.
- `docs/superpowers/specs/2026-04-19-autocomplete-design.md` and this plan file reference each other's locations (already done).
