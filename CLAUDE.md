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
├── after/ftplugin/           # Per-language overrides (15 filetypes + netrw)
├── assets/ivim.png           # Screenshot used in README.md
├── terminal.bashrc           # Tokyo Night bash prompt for Vim terminal
├── install.sh                # Local installer (symlink-based)
├── get-ivim.sh               # Online installer (curl | bash, like rustup)
├── README.md                 # User-facing docs + screenshot
├── LICENSE                   # Apache 2.0
└── .gitignore                # Ignores undodir/, .netrwhist, swap/backup files
```

## Architecture

- Uses Vim's native runtime path auto-loading: `colors/`, `plugin/`, `after/ftplugin/`
- No manual sourcing in vimrc — Vim loads everything automatically
- `plugin/` files load alphabetically: keymaps.vim, settings.vim, startscreen.vim, statusline.vim
- `vimrc` runs first: sets `encoding=utf-8`, `scriptencoding utf-8`, `mapleader`/`maplocalleader` (both Space), then loads colorscheme
- Targets Vim 8.0+ with graceful degradation on minimal builds

## Feature Guards

All optional features are guarded with `has()` checks:

| Feature                  | Guard                                          | Location         |
|--------------------------|------------------------------------------------|------------------|
| `termguicolors`          | `has('termguicolors')` + `$TERM != 'linux'`    | settings.vim     |
| `persistent_undo`        | `has('persistent_undo')`                        | settings.vim     |
| `mouse`                  | `has('mouse')`                                  | settings.vim     |
| `clipboard`              | `has('clipboard')`                              | keymaps.vim      |
| `terminal_ansi_colors`   | `has('terminal')`                               | tokyonight.vim   |
| `%{%...%}` syntax        | `has('patch-8.2.2854')`                         | statusline.vim   |

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
| `<leader>y/p/P` | Clipboard yank / paste after / paste before (normal+visual; echo warning if no `+clipboard`) |
| `<leader>a`     | Select all                      |
| `<leader>Tn/Tc` | New/close tab                   |

## Colorscheme

Tokyo Night "night" variant. Every highlight group defines both `guifg`/`guibg` and `ctermfg`/`ctermbg`. Custom `Stl*` groups for statusline and `Conceal` for netrw tree. Terminal ANSI colors via `g:terminal_ansi_colors`.

## Statusline

- Uses `%{...}` expressions (not `%!`) for correct per-window evaluation
- Active/inactive window differentiation via `WinEnter`/`WinLeave`/`BufWinEnter` autocommands; inactive statusline is hardcoded to `NORMAL` label
- Git branch cached in `b:git_branch` on `BufEnter`/`ShellCmdPost` — never calls `system()` during render
- Dynamic mode highlight colors on Vim 8.2.2854+, static fallback on older versions
- Custom tabline showing filename only (no buffer numbers)
- `Stl*` highlight groups include `StlModeNormal`, `StlModeInsert`, `StlModeVisual`, `StlModeReplace`, `StlModeCommand`

## Netrw File Explorer

- Tree view (`g:netrw_liststyle = 3`), no banner (`g:netrw_banner = 0`)
- Drawer width `g:netrw_winsize = 25`, opens via `Lexplore` (toggle)
- Smooth tree lines via syntax conceal (`|` → `│`) set in `after/ftplugin/netrw.vim`
- Smooth vertical split separator via global `fillchars` (not netrw-specific)
- `<CR>` / double-click call `IvimNetrwOpenInEditor()` — opens files in the previous window so the netrw drawer stays put
- Helper globals: `IvimNetrwGetTreePath()`, `IvimNetrwOpenInEditor()` (defined in `plugin/keymaps.vim`)

## Terminal

- Opens below with fixed `++rows=15 ++close`
- Launches bash with `--init-file terminal.bashrc` for Tokyo Night prompt
- `terminal.bashrc` sources `/etc/profile` and `~/.bashrc` first (full user env inherited), then sets a green-user / cyan-host / blue-cwd / purple-branch prompt using a nerd-font branch glyph; detached HEAD renders as `detached:<short-SHA>`
- Auto-closes terminal buffers on quit (`QuitPre` autocommand)
- `ivim_terminal_mouse` autogroup clears netrw mouse mappings that would otherwise leak into the terminal buffer
- ANSI colors set via `g:terminal_ansi_colors` in colorscheme (guarded by `has('terminal')`)

## Start Screen

- `plugin/startscreen.vim` triggers on `VimEnter` only when `argc() == 0` and the buffer is empty
- Renders a centered ASCII iVim logo + keymap hints; own highlight groups: `IvimLogo`, `IvimSubtitle`, `IvimHeader`, `IvimKey`, `IvimPrompt`
- Any alphanumeric / Enter / Esc / arrow / Space / `:` / `/` / `?` dismisses the screen via `:enew`; command keys (`:`, `/`, `?`) are re-fed so the user does not press twice

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

Both installers back up existing `~/.vim` and `~/.vimrc` with timestamps, verify symlink targets before removing during uninstall, refuse to run as root, and support `--help/-h`. `install.sh` creates the undo dir at `~/.local/share/vim/undodir` with `chmod 700`. `get-ivim.sh` clones to `~/.ivim` (updates via `git pull --ff-only`, aborts if an existing `~/.ivim` has a mismatched remote, cleans up a failed clone); its `--uninstall` also deletes `~/.ivim`, whereas `install.sh --uninstall` never touches the source directory.

## Ftplugin Overrides

All ftplugins use `setlocal` only. Two indent tiers:

| Indent  | Filetypes                                                          |
|---------|--------------------------------------------------------------------|
| 4-space | c, cpp, dockerfile, python, rust, sh                               |
| 2-space | css, html, javascript, json, lua, markdown, toml, typescript, yaml |

Notable per-type extras:
- `c` / `cpp` — `cinoptions=l1,g0,:0` (non-default label/access-specifier alignment)
- `python` — `textwidth=88` / `colorcolumn=88` (Black formatter line length)
- `rust` — `textwidth=100` / `colorcolumn=100` (rustfmt default)
- `markdown` — `wrap` + `linebreak` (visual soft-wrap; the only ftplugin to change display behavior)
- `netrw` — `conceallevel=2`, `|`→`│` conceal, custom statusline, `<CR>` → `IvimNetrwOpenInEditor()`

## Conventions

- Vimscript only — no plugins, no Lua, no external dependencies
- `scriptencoding utf-8` is declared in `vimrc` only; other files rely on it being set first
- All settings in `plugin/` use global `set`; all ftplugin settings use `setlocal`
- Script-local functions use `s:` prefix; global functions use topic prefixes: `Stl` (statusline), `Ivim` (everything else)
- `plugin/*.vim` files carry a one-line comment header; `after/ftplugin/*.vim` files have no header
- User input passed to `execute` must escape `/`, `\`, and `|`
- Install scripts use `set -euo pipefail`, quote all variables, verify symlink targets, refuse to run as root
