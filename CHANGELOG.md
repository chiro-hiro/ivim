# Changelog

All notable changes to iVim are documented here.

This project adheres to [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Dates are ISO 8601. iVim has no tagged versions yet — every change lives under **Unreleased** until a versioning scheme is adopted.

## [Unreleased]

### Added

- **IDE-style autocomplete** (`plugin/autocomplete.vim`) — popup auto-triggers as you type. Word characters (2+ prefix) fire keyword completion from the current file and open buffers; language-specific trigger characters (`.`, `>`, `<`, `:`, `/`, `$`) fire Vim's built-in `omnifunc`. Configured for 15 filetypes (c, cpp, css, dockerfile, html, javascript, json, lua, python, rust, sh, toml, typescript, yaml) plus markdown opt-out. Pure Vimscript, plugin-free.
- **Popup navigation keymaps** — `<Tab>` / `<S-Tab>` navigate, `<CR>` accepts a selected item (no newline), `<Esc>` dismisses popup + exits insert mode. All context-sensitive (`<expr>` guarded by `pumvisible()`); original key behaviour preserved when no popup is showing.
- **Start screen autocomplete section** — the splash screen's keymap reference now includes an "AUTOCOMPLETE (popup)" block.
- **TOML and YAML syntax colors** — Tokyo Night-themed highlight overrides. Keys in white+bold, tables / section headers in blue+bold, with typed accents for strings (green), numbers/booleans (orange), dates / nulls / doc markers / escapes (magenta), anchors / aliases / tags (yellow), and italic-gray comments. Every group defines both `gui` and `cterm`.
- **Colorscheme groups**: `ModeMsg` (green+bold for `-- INSERT --` etc.) and `Underlined` (blue+underline); previously fell back to Vim defaults.
- **Project memory / documentation** — `CLAUDE.md` gained `## Autocomplete` and `## Start Screen` sections, a feature-guard row for `complete_info()`, and `b:ivim_*` as a documented cross-file buffer-variable convention.

### Changed

- **`filetype plugin indent on`** relocated from `plugin/settings.vim` to `vimrc` — ensures Vim's built-in ftplugin loader registers its `FileType` autocmd before any `plugin/*.vim` file.
- **Git branch statusline cache** is now script-local and keyed by file directory (`s:branch_cache`), not per-buffer (`b:git_branch`). N buffers in the same repo cost one `system('git -C <dir> rev-parse …')` call; cache is cleared on `ShellCmdPost` so `:!git …` still refreshes.
- **Terminal opener** uses `term_start(['bash', '--init-file', rcfile], {…})` with a list argument — not `:execute 'below terminal …'`. Vim's `:terminal` splits its command string on whitespace regardless of quoting, which broke when the install path contained spaces.
- **Terminal `<leader>t` keymap** wrapped in `has('terminal')`; minimal Vim builds (`vim-tiny`) now show a warning instead of erroring.
- **Keyword `<C-n>`** now fires only at the **second word character of a new word**, not on every subsequent word char. Previously the popup closed-and-re-opened on every keystroke, blocking users who wanted to type past the suggestions.
- **`README.md`** install section advises readers to inspect `get-ivim.sh` before piping to bash.

### Fixed

- **Rust / Lua / C++ autocomplete freeze on `::` and similar multi-char operators.** The trigger list included `:`, so typing `::` fired `syntaxcomplete#Complete` twice in rapid succession; queued `<C-x><C-o>` pairs then leaked into the typeahead buffer, leaving Vim in a state where `<C-o>` was interpreted as "execute one normal command" and swallowed the user's next keystroke. Removed `:` from Rust / Lua / C++ trigger lists; added a defensive duplicate-trigger-char skip in the engine.
- **Broken color escapes** in `get-ivim.sh` `info:` / `ok:` / `warn:` / `err:` output — previous polish commit moved color variables into `printf '%s'` arguments, but `printf` only interprets `\033` inside format strings. Switched to ANSI-C quoting (`$'\033[1m'`) so the variables contain real ESC bytes.
- **Insert-mode click into non-modifiable buffer** (e.g., mouse-click into the netrw sidebar) no longer errors. A `WinEnter` / `BufEnter` autocmd calls `stopinsert` on buffers with `!&modifiable`.
- **netrw helper** `IvimNetrwOpenInEditor` guards against a missing `b:netrw_curdir` when called outside a netrw buffer.
- **Terminal `<Esc>` handling** — maps to `<C-e><Esc>` when popup is visible, so pressing Esc once dismisses popup AND exits insert mode (previously took two presses).
- **Autocomplete load ordering** — engine's `FileType` autocmd now reliably runs after ftplugins have set `omnifunc` and `b:ivim_complete_triggers`.

### Security

- **Backup restore TOCTOU hardening** (`install.sh`, `get-ivim.sh`). `find_latest_backup` now rejects two attack vectors: (1) non-integer timestamp suffixes (crafted filenames) and (2) files not owned by the current user. Prevents a shared-HOME attacker from planting `~/.vim.bak.<huge_timestamp>` → hostile symlink that would be picked up on the next uninstall-and-restore.
- **Signal trap rollback** (`install.sh`, `get-ivim.sh`). Backups made during an install are tracked in `BACKUPS_MADE`; a `trap … EXIT INT TERM` restores them if the install is interrupted between `mv` (backup) and `ln -s` (symlink creation). Previously, `SIGINT` could leave the user's `~/.vim` gone and only recoverable manually.
- **PATH hijack fix in `terminal.bashrc`**. `git` binary path is now resolved (`command -v git`) *before* sourcing `/etc/profile` and `~/.bashrc`. If those init files prepend an attacker-controlled directory to `PATH`, the cached absolute path prevents a malicious `git` from running on every prompt redraw.
- **Recursion guard no longer exported**. `_IVIM_TERMINAL_SOURCED` was previously exported, leaking to every child process of the Vim terminal. Subprocesses could introspect it to detect the iVim context. Now shell-local.
- **`.gitignore` expanded** — added patterns for secret files (`*.pem`, `*.key`, `*.env`, `.envrc`, `id_rsa*`, `id_ed25519*`, `credentials`), editor artifacts (`tags`, `Session.vim`, `*.un~`, `*.swo`, `*.orig`), and Windows OS artifact (`Thumbs.db`). Guards against accidental commits by future contributors.

### Known limitations (not fixed)

These are design properties of iVim's install flow, documented here so users can make informed choices:

- `curl … | bash` has no checksum or signature verification. Readers are advised in the README to inspect `get-ivim.sh` before running.
- `get-ivim.sh` always tracks `HEAD` of `master`; there are no tagged versions or signed commits. A compromised maintainer account could ship code to all users on their next `get-ivim.sh` run or `git pull`.
- `git pull --ff-only` in the update path does not detect force-pushes that create a fast-forward-compatible history.
- JavaScript / TypeScript `omnifunc` (`javascriptcomplete#CompleteJS`) is Vim's built-in DOM-era dictionary, not a language server. Module-aware completion requires external tooling iVim deliberately does not ship.
