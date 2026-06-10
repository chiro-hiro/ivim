# iVim

Plugin-free Vim configuration with Tokyo Night theme.

## Project Structure

```
ivim/
├── vimrc                     # Entry point: encoding, leader (Space), colorscheme
├── colors/tokyonight.vim     # Tokyo Night (night) colorscheme — gui + cterm256
├── plugin/
│   ├── autocomplete.vim      # IDE-style auto-completion engine + popup keymaps
│   ├── context_menu.vim      # Right-click Copy/Cut/Paste menu (PopUp)
│   ├── keymaps.vim           # Key mappings (Space leader), terminal, search
│   ├── settings.vim          # Core editor settings with feature guards
│   ├── startscreen.vim       # Start screen with keymap help on empty Vim launch
│   └── statusline.vim        # Custom statusline + tabline with mode colors
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
- `plugin/` files load alphabetically: autocomplete.vim, context_menu.vim, keymaps.vim, settings.vim, startscreen.vim, statusline.vim
- `vimrc` runs first: sets `encoding=utf-8`, `scriptencoding utf-8`, `mapleader`/`maplocalleader` (both Space), enables `filetype plugin indent on` (must precede plugin/ so ftplugin's FileType autocmd registers first), then loads colorscheme
- Targets Vim 8.0+ with graceful degradation on minimal builds

## Feature Guards

All optional features are guarded with `has()` checks:

| Feature                  | Guard                                          | Location         |
|--------------------------|------------------------------------------------|------------------|
| `termguicolors`          | `has('termguicolors')` + `$TERM != 'linux'`    | settings.vim     |
| `persistent_undo`        | `has('persistent_undo')`                        | settings.vim     |
| `mouse`                  | `has('mouse')`                                  | settings.vim     |
| `clipboard`              | `has('clipboard')`                              | keymaps.vim, context_menu.vim |
| `<Cmd>` keymap prefix    | `has('patch-8.2.1978')`                         | context_menu.vim |
| `terminal_ansi_colors`   | `has('terminal')`                               | tokyonight.vim   |
| terminal keymap `<leader>t` | `has('terminal')`                            | keymaps.vim      |
| `complete_info()`        | `has('patch-8.0.1775')`                         | autocomplete.vim |
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

Tokyo Night "night" variant. Every highlight group defines both `guifg`/`guibg` and `ctermfg`/`ctermbg`. Custom `Stl*` groups for statusline, `Conceal` for netrw tree, and filetype-specific overrides for TOML and YAML (see below). Terminal ANSI colors via `g:terminal_ansi_colors`.

### Filetype-specific highlights (TOML, YAML)

TOML and YAML get explicit overrides so structural elements stand out:

| Element                                                                           | Style         |
|-----------------------------------------------------------------------------------|---------------|
| Keys (`tomlKey*`, `yamlBlockMappingKey`, `yamlFlowMappingKey`)                    | white + bold  |
| Tables / section headers (`tomlTable`, `tomlTableArray`)                          | blue + bold   |
| Strings (`tomlString`, `yamlFlowString`)                                          | green         |
| Numbers & booleans (`tomlInteger`, `tomlFloat`, `tomlBoolean`, `yamlInteger`, `yamlFloat`, `yamlBool`) | orange |
| Dates, null, doc markers, escapes (`tomlDate`, `tomlEscape`, `yamlNull`, `yamlDocumentStart/End`, `yamlSingleEscape`) | magenta |
| Anchors, aliases, tags (`yamlAnchor`, `yamlAlias`, `yamlNodeTag`)                 | yellow        |
| Comments (`tomlComment`, `yamlComment`)                                           | gray italic   |

Other filetypes rely on Vim's default syntax → generic-group links (`String`, `Number`, `Type`, etc.) that the base colorscheme defines.

## Statusline

- Uses `%{...}` expressions (not `%!`) for correct per-window evaluation
- Active/inactive window differentiation via `WinEnter`/`WinLeave`/`BufWinEnter` autocommands; inactive statusline is hardcoded to `NORMAL` label
- Git branch cached per-directory in script-local `s:branch_cache` dict (keyed by `expand('%:p:h')`); `b:git_branch` is set on `BufEnter` from the cache. N buffers in the same repo cost one `system('git -C <dir> rev-parse …')` call; cache is cleared on `ShellCmdPost` so `:!git …` refreshes the statusline. No `system()` during render.
- Dynamic mode highlight colors on Vim 8.2.2854+, static fallback on older versions
- Custom tabline showing filename only (no buffer numbers)
- `Stl*` highlight groups include `StlModeNormal`, `StlModeInsert`, `StlModeVisual`, `StlModeReplace`, `StlModeCommand`
- The statusline shows the mode, so `settings.vim` sets `noshowmode` to suppress Vim's redundant `-- INSERT --` / `-- VISUAL --` in the command line

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
| `b:ivim_complete_triggers`    | List of trigger sequences that fire omnifunc dispatch; entries may be multi-char operators (`->`, `::`) which match in full so a bare `>`/`:` does not trigger (default `['.']`; empty list = keyword-only) |

The engine normalizes `b:ivim_complete_triggers` into `b:ivim_triggers` (longest-first list) on `FileType` so the hot path tests multi-char operators before single chars. `&omnifunc` presence is checked live per keystroke (not cached) so a buffer whose omnifunc is set/cleared after `FileType` still dispatches correctly.

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

## Context Menu

Right-click context menu (`plugin/context_menu.vim`) exposes Copy / Cut / Paste via Vim's native `PopUp` mechanism (`:popup PopUp` triggered by `<RightRelease>`). All operations go through the `+` register (system clipboard).

- **Normal mode:** Copy = yank current line, Cut = delete current line, Paste = paste after cursor
- **Visual mode:** Copy / Cut = selection, Paste = replace selection
- **Insert mode:** Paste only (`<C-r>+`) — Copy/Cut skipped (no selection semantics)

On Vim 8.2.1978+ the trigger uses `<Cmd>popup PopUp<CR>` so insert mode is preserved across the menu; older Vims fall back to `:popup` / `<C-o>:popup`. Without `+clipboard` the file `finish`es early — no menu, no `<RightRelease>` remap, Vim's default right-click (extend visual selection) is preserved. There is no "clipboard not available" toast; a right-click menu that can't use the system clipboard has no reason to exist.

## Netrw File Explorer

- Tree view (`g:netrw_liststyle = 3`), no banner (`g:netrw_banner = 0`)
- Drawer width `g:netrw_winsize = 25`, opens via `Lexplore` (toggle)
- Smooth tree lines via syntax conceal (`|` → `│`) set in `after/ftplugin/netrw.vim`
- Smooth vertical split separator via global `fillchars` (not netrw-specific)
- `<CR>` / double-click call `IvimNetrwOpenInEditor()` — opens files in the previous window so the netrw drawer stays put
- For a directory, `IvimNetrwOpenInEditor()` hands off to netrw via `normal <Plug>NetrwLocalBrowseCheck`, gated on `exists('*netrw#LocalBrowseCheck')` — NOT `maparg()`, which cannot find a buffer-local `<Plug>` map by name (a `maparg` guard is always false → folders never expand)
- `after/ftplugin/netrw.vim` deliberately sets **no** `b:undo_ftplugin`: netrw re-fires `FileType` on its own buffer during routine use (list-style `i`, directory change), and any undo line makes Vim reload netrw's own ftplugin mid-operation → `E749: Empty buffer`
- Helper globals: `IvimNetrwGetTreePath()`, `IvimNetrwOpenInEditor()` (defined in `plugin/keymaps.vim`)

## Terminal

- Opens below with fixed 15 rows and `term_finish='close'`
- Entire `<leader>t` keymap block is guarded by `has('terminal')`; on minimal Vim builds the keymap prints a warning instead of erroring
- Uses `term_start(['bash', '--init-file', l:rcfile], {…})` with a list argument — NOT `:execute 'below terminal …'` — so paths containing spaces do not misparse (Vim's `:terminal` splits its command on whitespace regardless of quoting)
- `terminal.bashrc` sources `/etc/profile` and `~/.bashrc` first (full user env inherited), then sets a green-user / cyan-host / blue-cwd / purple-branch prompt (branch segment is space-prefixed, no font dependency); detached HEAD renders as `detached:<short-SHA>`
- `terminal.bashrc` guards against recursive sourcing via `_IVIM_TERMINAL_SOURCED` so any `~/.bashrc` loop is a no-op on re-entry
- Auto-closes terminal buffers when Vim exits: a `QuitPre` autocommand (`s:CloseTerminalsOnExit`) gated on the last non-terminal window — so a single-window or aborted `:q` never kills terminals, and `:qall` never trips `E947` (job still running). `<leader>x` (`:xall`) does not fire `QuitPre` on every Vim version, so it routes through `s:SaveQuitAll`, which wipes terminals before `:xall` to avoid `E948`
- `ivim_terminal_mouse` autogroup clears netrw mouse mappings that would otherwise leak into the terminal buffer
- ANSI colors set via `g:terminal_ansi_colors` in colorscheme (guarded by `has('terminal')`)

## Start Screen

- `plugin/startscreen.vim` triggers on `VimEnter` only when `argc() == 0` and the buffer is empty
- Renders a centered ASCII iVim logo + keymap hints organized in section blocks (FILE, BUFFERS, CLIPBOARD, TERMINAL, AUTOCOMPLETE, SPLITS, SEARCH, QUICKFIX, TABS, OTHER); own highlight groups: `IvimLogo`, `IvimSubtitle`, `IvimHeader`, `IvimKey`, `IvimPrompt`
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

All ftplugins use `setlocal` only; every **language** ftplugin also sets `b:undo_ftplugin` to revert its `setlocal` options and `unlet! b:ivim_*` on filetype change (netrw is the deliberate exception — see Netrw File Explorer). Two indent tiers:

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

## Testing

No test framework — verify by sourcing/driving Vim headlessly:

- Source-check one file: `vim -Nu NONE -i NONE -es -c 'source <file>' -c 'qa!'` (empty output = clean)
- Smoke-test the full config: set `rtp` to `<repo>,$VIMRUNTIME,<repo>/after` then `source <repo>/vimrc`. Vim does **not** auto-derive the `after/` dir from an rtp entry — list it explicitly. The installed `~/.vim → ~/.ivim` is on the default rtp and shadows the working tree, so always set `rtp` explicitly.
- Interactive netrw (`<CR>` on a folder, `i` list-style) can't be tested in `-es` mode — it throws spurious `E749`/`E31`. Drive a real `vim` through a Python `pty` (`pty.fork()` + `os.write`/`select`) and scrape the screen for `Error`/`E\d+`.
- Installer tests: run with a throwaway `$HOME`. For `install.sh`, point `SCRIPT_DIR` at a **copy** of the repo — a bare `ln -s` onto an existing symlink-to-directory nests a stray link inside the source.
- `bash -n` + `shellcheck` the installers. macOS `cat` lacks `-A`.

## Conventions

- Vimscript only — no plugins, no Lua, no external dependencies
- Installer symlinks use `ln -sfn` (force + no-dereference) so re-linking is idempotent and never nests inside an existing symlink-to-directory
- `scriptencoding utf-8` is declared in `vimrc` only; other files rely on it being set first
- All settings in `plugin/` use global `set`; all ftplugin settings use `setlocal`
- No hard tabs for indentation — global `set expandtab` plus each ftplugin repeats `setlocal expandtab`; autoindent is enabled globally (`set autoindent` + `filetype plugin indent on`) so every Vim-shipped language gets smart indentation
- Script-local functions use `s:` prefix; global functions use topic prefixes: `Stl` (statusline), `Ivim` (everything else)
- Cross-file buffer-local state uses `b:ivim_*` prefix (e.g. `b:ivim_complete_triggers`, `b:ivim_autocomplete_disable`)
- `plugin/*.vim` files carry a one-line comment header; `after/ftplugin/*.vim` files have no header
- User input passed to `execute` must be escaped for its search context: a `/`-delimited very-nomagic (`\V`) pattern escapes only `/` and `\` (a literal `|` must NOT be escaped — `\|` is alternation in `\V`); other contexts escape whatever is special there
- Install scripts use `set -euo pipefail`, quote all variables, verify symlink targets, refuse to run as root
