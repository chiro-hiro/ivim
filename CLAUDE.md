# iVim

Plugin-free Vim configuration with Tokyo Night theme.

## Project Structure

```
ivim/
├── vimrc                     # Entry point: encoding, leader (Space), colorscheme
├── colors/tokyonight.vim     # Tokyo Night (night) colorscheme — gui + cterm256
├── plugin/
│   ├── settings.vim          # Core editor settings with feature guards
│   ├── keymaps.vim           # Key mappings (Space leader), terminal, search
│   ├── statusline.vim        # Custom statusline + tabline with mode colors
│   └── startscreen.vim       # Start screen with keymap help on empty Vim launch
├── after/ftplugin/           # Per-language overrides (13 filetypes + netrw)
├── terminal.bashrc           # Tokyo Night bash prompt for Vim terminal
├── install.sh                # Local installer (symlink-based)
└── get-ivim.sh               # Online installer (curl | bash, like rustup)
```

## Architecture

- Uses Vim's native runtime path auto-loading: `colors/`, `plugin/`, `after/ftplugin/`
- No manual sourcing in vimrc — Vim loads everything automatically
- `plugin/` files load alphabetically: keymaps.vim, settings.vim, statusline.vim
- `vimrc` runs first: sets leader and colorscheme before plugin/ files load
- Targets Vim 8.0+ with graceful degradation on minimal builds

## Feature Guards

All optional features are guarded with `has()` checks:

| Feature           | Guard                                          | Location        |
|-------------------|------------------------------------------------|-----------------|
| `termguicolors`   | `has('termguicolors')` + `$TERM != 'linux'`    | settings.vim    |
| `persistent_undo` | `has('persistent_undo')`                        | settings.vim    |
| `mouse`           | `has('mouse')`                                  | settings.vim    |
| `clipboard`       | `has('clipboard')`                              | keymaps.vim     |
| `%{%...%}` syntax | `has('patch-8.2.2854')`                         | statusline.vim  |

## Key Mappings

Leader is Space. Only `<leader>` bindings are added — no default Vim keys are overridden.

| Mapping         | Action                          |
|-----------------|---------------------------------|
| `<leader>w`     | Save                            |
| `<leader>q`     | Quit all                        |
| `<leader>x`     | Save and quit all               |
| `<leader>e`     | Toggle file explorer (Lexplore) |
| `<leader>t`     | Open terminal below             |
| `<leader>bn/bp` | Next/prev buffer                |
| `<leader>bd`    | Delete buffer                   |
| `<leader>bl`    | List buffers                    |
| `<leader>sv/sh` | Vertical/horizontal split       |
| `Ctrl+h/j/k/l`  | Navigate splits                |
| `<leader>=`     | Equalize splits                 |
| `<leader>/`     | Clear search highlight          |
| `<leader>sf`    | Search in files (vimgrep)       |
| `<leader>co/cc` | Open/close quickfix             |
| `]q` / `[q`     | Next/prev quickfix item         |
| `<leader>y/p`   | Clipboard yank/paste (guarded)  |
| `<leader>a`     | Select all                      |
| `<leader>Tn/Tc` | New/close tab                   |

## Colorscheme

Tokyo Night "night" variant. Every highlight group defines both `guifg`/`guibg` and `ctermfg`/`ctermbg`. Custom `Stl*` groups for statusline and `Conceal` for netrw tree. Terminal ANSI colors via `g:terminal_ansi_colors`.

## Statusline

- Uses `%{...}` expressions (not `%!`) for correct per-window evaluation
- Active/inactive window differentiation via `WinEnter`/`WinLeave` autocommands
- Git branch cached in `b:git_branch` on `BufEnter`/`FocusGained` — never calls `system()` during render
- Dynamic mode highlight colors on Vim 8.2.2854+, static fallback on older versions
- Custom tabline showing filename only (no buffer numbers)

## Netrw File Explorer

- Tree view (`g:netrw_liststyle = 3`)
- No banner (`g:netrw_banner = 0`)
- Smooth tree lines via syntax conceal (`|` → `│`)
- Smooth vertical split separator via `fillchars`
- Double-click to open/expand

## Terminal

- Opens below at ~1/3 height with `++close`
- Launches bash with `--init-file terminal.bashrc` for Tokyo Night prompt
- Auto-closes terminal buffers on quit (`QuitPre` autocommand)
- ANSI colors set via `g:terminal_ansi_colors` in colorscheme

## Install

**Local (from clone):**
```bash
./install.sh            # Backup existing config, symlink, create undo dir
./install.sh --uninstall  # Remove symlinks, restore backup
```

**Online (curl):**
```bash
curl -fsSL https://raw.githubusercontent.com/chiro-hiro/ivim/master/get-ivim.sh | bash
curl -fsSL https://raw.githubusercontent.com/chiro-hiro/ivim/master/get-ivim.sh | bash -s -- --uninstall
```

Both installers back up existing `~/.vim` and `~/.vimrc` with timestamps, and verify symlink targets before removing during uninstall.

## Conventions

- Vimscript only — no plugins, no Lua, no external dependencies
- All settings in `plugin/` use global `set`; all ftplugin settings use `setlocal`
- Script-local functions use `s:` prefix; global statusline functions use `Stl` prefix
- User input passed to `execute` must escape `/`, `\`, and `|`
- Install scripts use `set -euo pipefail`, quote all variables, verify symlink targets
