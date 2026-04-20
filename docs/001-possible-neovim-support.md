# 001 — Possible Neovim Support

**Status:** Proposal / exploration — not yet implemented
**Target:** Neovim ≥ 0.7.2
**Date:** 2026-04-21

## Summary

Evaluate what it would take to make iVim run as-is (or with minimal, contained branches) on Neovim 0.7.2 and newer. Short verdict: most of the codebase is compatible. Two features require a `has('nvim')` branch: the terminal opener and the right-click context menu. A handful of feature guards need an additional Neovim version check. Total estimated change: ~50 lines across four files.

## Goal

Let a user who installs iVim under Neovim get the same user-visible experience (colorscheme, statusline, autocomplete, keymaps, start screen, ftplugin overrides) without breaking anything that currently works in Vim. Features that genuinely cannot be preserved without introducing Lua or a plugin should be gracefully scoped to "Vim only" rather than silently broken.

## Non-goals

- No Lua, no plugins. iVim's "plugin-free, Vimscript only, no external dependencies" invariant holds for Neovim just as for Vim.
- No Neovim-exclusive features (LSP, Treesitter, `vim.lsp`, etc.). If Neovim users want those, they should reach for a Neovim-first distribution.
- Dropping support for any Vim version iVim currently targets (8.0+).

## Compatibility survey

### Works unchanged on Neovim 0.7.2

| Area | Notes |
|------|-------|
| `colors/tokyonight.vim` | `hi` commands, `g:terminal_ansi_colors`, `hi clear` / `syntax reset` — identical semantics. |
| `plugin/settings.vim` | Every option (`completeopt`, `wildmenu`, `autoindent`, `termguicolors` guard, etc.) is standard. |
| `plugin/keymaps.vim` | Leader bindings, search, splits, buffers, tabs, clipboard branches — all standard. Terminal opener is the one exception (see below). |
| `plugin/statusline.vim` | `%{...}` and `%{%...%}` both work. One guard needs updating (see below). |
| `plugin/startscreen.vim` | `VimEnter`, `nnoremap <buffer>`, syntax-match, highlight groups — all standard. |
| `plugin/autocomplete.vim` | `TextChangedI`, `feedkeys()`, `pumvisible()`, `complete_info()`, `completeopt` — all present in Nvim 0.7.2. One guard needs updating. |
| `after/ftplugin/**` | Filetype detection and load order are identical (both Vim and Neovim run `after/ftplugin/<ft>.vim` after the built-in ftplugin). |
| Netrw | Bundled with Neovim through 0.10.x. Our helper functions (`IvimNetrwGetTreePath`, `IvimNetrwOpenInEditor`) rely only on standard netrw variables. |

### Breaks without a Vim/Neovim branch

**1. Terminal opener** — `plugin/keymaps.vim:OpenTerminal`

Current code:
```vim
below new
call term_start(['bash', '--init-file', l:rcfile], {
      \ 'curwin': 1,
      \ 'term_rows': 15,
      \ 'term_finish': 'close',
      \ })
```

`term_start()` is Vim-only. Neovim's equivalent is `termopen()` but:
- `termopen()` only works in an empty buffer (we'd need `:enew` first, not `:new`).
- Neovim's `:terminal` command enters terminal mode, where our `QuitPre` cleanup needs different logic.
- Options differ: no `term_rows` (use `resize`), no `term_finish` (register `TermClose` autocmd for close-on-exit).

**Fix:** `has('nvim')` branch, ~10 lines.

```vim
if has('nvim')
  " Neovim path
  below new
  call termopen(['bash', '--init-file', l:rcfile])
  resize 15
  " Close window when job exits
  autocmd TermClose <buffer> ++once silent! bwipeout!
  startinsert
else
  " Vim path (current code)
  below new
  call term_start(['bash', '--init-file', l:rcfile], {
        \ 'curwin': 1,
        \ 'term_rows': 15,
        \ 'term_finish': 'close',
        \ })
endif
```

**2. Right-click context menu** — `plugin/context_menu.vim`

`:popup PopUp` is Vim-only. Neovim does not implement `:popup` as of 0.7.2 (and, at the time of writing, has no plans to add it); attempting to use it yields "E319: Sorry, the command is not available in this version" or a no-op.

Three options (see below for recommendation):

- **A) Skip on Neovim.** Wrap the file in `if !has('nvim')`. Nvim users get no right-click menu — the mouse event falls through to Vim's default (extend visual selection). Zero extra code.
- **B) Replace `:popup PopUp` with `inputlist()` on Neovim.** The user sees a numbered prompt at the bottom of the screen instead of a floating menu. Functionally equivalent, stylistically less polished. ~15 lines of shared code.
- **C) Lua `vim.ui.select()` bridge on Nvim.** Idiomatic Neovim, no custom UI code on our side, but requires one `:lua` call — violates the "no Lua" invariant.

### Feature guards needing updates

Three `has('patch-…')` checks are Vim-specific. Neovim doesn't implement Vim's patch numbers but provides the same functionality under `has('nvim-X.Y')` or `has('nvim')`.

| File | Current guard | Proposed guard | Reason |
|------|---------------|----------------|--------|
| `plugin/statusline.vim` | `has('patch-8.2.2854')` | `has('patch-8.2.2854') \|\| has('nvim-0.5')` | `%{%...%}` syntax has been in Nvim since 0.5 |
| `plugin/autocomplete.vim` | `has('patch-8.0.1775')` | `has('patch-8.0.1775') \|\| has('nvim')` | `complete_info()` has been in Nvim since early 0.x |
| `plugin/context_menu.vim` | `has('patch-8.2.1978')` | `has('patch-8.2.1978') \|\| has('nvim-0.5')` | `<Cmd>` keymap prefix has been in Nvim since 0.5 |

## Options for the context menu (the hard one)

### A) Skip on Neovim

Simplest. Wrap `plugin/context_menu.vim` contents in `if !has('nvim') | finish | endif` (at top). Neovim users don't get the feature; no error, no weird behaviour.

**Pros:** zero code, zero risk of bugs on Nvim.
**Cons:** feature gap — Nvim users pay with their mouse, no right-click menu. Users might assume iVim just doesn't support mouse on Nvim.

### B) `inputlist()` fallback on Neovim

Mode-aware `inputlist()` prompt: prints `1. Copy / 2. Cut / 3. Paste` at the bottom; user types a digit to pick. On Vim, the existing `:popup PopUp` path is preserved.

```vim
function! s:ShowContextMenu() abort
  " Respect mode semantics — only list Paste in insert mode, etc.
  let l:choice = inputlist(['Choose:', '1. Copy', '2. Cut', '3. Paste'])
  if     l:choice == 1 | " Copy
  elseif l:choice == 2 | " Cut
  elseif l:choice == 3 | " Paste
  endif
endfunction
```

**Pros:** pure Vimscript; no dependency on Neovim-specific APIs; works on every Vim build too.
**Cons:** Nvim users get a less polished UI (no floating popup). Requires manually building the per-mode command routing that `:popup PopUp` handles natively.

### C) `:lua vim.ui.select()` on Neovim

```vim
if has('nvim')
  function! s:ShowContextMenu() abort
    call v:lua.require'...'...  " not even valid, just illustrative
  endfunction
endif
```

**Pros:** idiomatic Nvim. Respects user's `vim.ui.select` override (e.g., telescope integration).
**Cons:** **violates the no-Lua invariant** iVim has maintained. Introduces a Lua dependency for one feature. Slippery slope.

## Recommendation

**B) `inputlist()` fallback.** Preserves the "Vimscript only, no Lua, no plugins" invariant that defines iVim. Functional parity for Copy / Cut / Paste. Minor UX difference (bottom-of-screen prompt vs floating popup).

If the UX gap is intolerable, fall back to **A** — skip the feature on Nvim and document it. Do NOT pick **C**.

## Scope and estimated effort

| Change | Lines | File |
|--------|-------|------|
| Terminal opener `has('nvim')` branch | ~10 | `plugin/keymaps.vim` |
| Statusline guard update | 1 | `plugin/statusline.vim` |
| Autocomplete guard update | 1 | `plugin/autocomplete.vim` |
| Context menu: `<Cmd>` guard update + nvim fallback (option B) | ~20 | `plugin/context_menu.vim` |
| CLAUDE.md: new `## Neovim compatibility` section + guards table updates | ~15 | `CLAUDE.md` |
| README: mention Nvim 0.7.2+ support in the features list | ~3 | `README.md` |
| CHANGELOG: new Added entry under Unreleased | ~3 | `CHANGELOG.md` |
| **Total** | **~53 lines across 7 files** | |

## Verification plan

Manual, since iVim has no automated test suite.

1. Install Neovim ≥ 0.7.2 on the dev box (if not present).
2. Run `nvim` with `$XDG_CONFIG_HOME=/tmp/test-ivim` pointing at the iVim install.
3. Walk through the existing end-to-end checklist (from `docs/superpowers/plans/2026-04-19-autocomplete.md` Task 13), adapted for Neovim:
   - Colorscheme renders (tokyo night colors in each ftplugin buffer).
   - Statusline renders (dynamic mode colors; fallback branch works on Nvim via the `nvim-0.5` guard).
   - Autocomplete fires as expected in each filetype; `::` doesn't freeze.
   - Start screen appears on empty Nvim launch.
   - `<leader>t` opens a terminal (via `termopen()` branch); detached HEAD / branch prompt renders.
   - Right-click context menu shows the Nvim fallback; Copy / Cut / Paste all route through `"+` correctly.
   - `<leader>y` / `<leader>p` still work.
   - netrw: `<leader>e` toggles, `<CR>` opens in editor window.
4. On Vim 8.0+ (regression check): every previously-working feature still works.

## Open questions

1. **Which context-menu option (A, B, or C)?** — see recommendation above.
2. **Do we want Neovim support documented as a "supported target" or "best-effort"?** README currently says "Targets Vim 8.0+". Should become "Targets Vim 8.0+ and Neovim 0.7.2+" if we're committing to support it, or remain focused on Vim with Nvim as a happy accident.
3. **Testing environment** — is Neovim 0.7.2 available on the dev box, or will a newer version (0.9/0.10) be used instead? Later versions may expose incompatibilities we can't catch testing against 0.7.2.
4. **Install script branching** — should `install.sh` / `get-ivim.sh` also symlink `~/.config/nvim/init.vim` → this repo's `vimrc` (plus `~/.config/nvim → ~/.vim`)? Or is Nvim users' responsibility to wire it up themselves?

## Next steps

Blocked on: answer to open question 1 (menu option) and 4 (installer scope). Once those are settled, a follow-up implementation plan can be written under `docs/superpowers/plans/` and executed in one pass (small enough not to need subagent-driven decomposition).
