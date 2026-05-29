#!/usr/bin/env bash
set -euo pipefail

# iVim installer — symlinks ~/.vim and ~/.vimrc to this directory

if [ "$(id -u)" -eq 0 ]; then
  echo "Error: Do not run this script as root or with sudo." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%s)"
VIM_DIR="$HOME/.vim"
VIMRC="$HOME/.vimrc"
UNDO_DIR="$HOME/.local/share/vim/undodir"

usage() {
  echo "Usage: $0 [--uninstall | --help | -h]"
  echo ""
  echo "  (no args)    Install iVim (backup existing config, create symlinks)"
  echo "  --uninstall  Remove symlinks, restore most recent backup if available"
  echo "  --help, -h   Show this help message"
}

# Track backups made during this run so we can restore them on interrupt.
BACKUPS_MADE=()

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="${target}.bak.${TIMESTAMP}"
    # Two installs within the same second would otherwise reuse the same
    # backup name and silently clobber the earlier backup.
    local n=1
    while [ -e "$backup" ] || [ -L "$backup" ]; do
      backup="${target}.bak.${TIMESTAMP}.${n}"
      n=$((n + 1))
    done
    echo "  Backing up: $target → $backup"
    mv "$target" "$backup"
    BACKUPS_MADE+=("$target" "$backup")
  fi
}

# Restore any backups from this run — used by the signal/ERR trap so an
# interrupted install (killed between mv and ln -s) does not leave the user
# without a ~/.vim at all.
restore_on_failure() {
  local exit_code=$?
  # Only restore if we exited abnormally AND the install hasn't completed.
  if [ "$exit_code" -ne 0 ] && [ "${INSTALL_OK:-0}" -ne 1 ]; then
    local i=0
    while [ "$i" -lt "${#BACKUPS_MADE[@]}" ]; do
      local target="${BACKUPS_MADE[$i]}"
      local backup="${BACKUPS_MADE[$((i + 1))]}"
      if [ ! -e "$target" ] && [ -e "$backup" ]; then
        mv "$backup" "$target" 2>/dev/null && \
          echo "  Rolled back: $backup → $target" >&2
      fi
      i=$((i + 2))
    done
  fi
}
trap restore_on_failure EXIT INT TERM

find_latest_backup() {
  local target="$1"
  # Find the most recent .bak.* file by timestamp suffix.
  # Rejects non-integer suffixes (crafted filenames) and files not owned by
  # the current user (TOCTOU / shared-HOME attack where a different user
  # plants ~/.vim.bak.<big_ts> → hostile symlink, intending to be picked up
  # on the next uninstall-and-restore).
  local latest=""
  local latest_ts=0
  shopt -s nullglob
  for f in "${target}.bak."*; do
    local ts="${f##*.bak.}"
    if ! [[ "$ts" =~ ^[0-9]+$ ]]; then
      continue
    fi
    if [ ! -O "$f" ]; then
      continue
    fi
    if [ "$ts" -gt "$latest_ts" ]; then
      latest_ts="$ts"
      latest="$f"
    fi
  done
  shopt -u nullglob
  echo "$latest"
}

install() {
  # If both symlinks already point here, the user has just pulled new
  # commits into the existing clone and re-run install.sh. There is
  # nothing to do beyond confirming so — no new backups, no relink.
  if [ -L "$VIM_DIR" ] && [ "$(readlink "$VIM_DIR")" = "$SCRIPT_DIR" ] \
     && [ -L "$VIMRC" ] && [ "$(readlink "$VIMRC")" = "$SCRIPT_DIR/vimrc" ]; then
    echo "iVim already installed — symlinks point at $SCRIPT_DIR."
    echo "Pull the latest commits in this directory to update."
    INSTALL_OK=1
    return
  fi

  echo "Installing iVim..."
  echo ""

  # Backup existing config
  backup_if_exists "$VIM_DIR"
  backup_if_exists "$VIMRC"

  # Create symlinks
  ln -s "$SCRIPT_DIR" "$VIM_DIR"
  echo "  Linked: $VIM_DIR → $SCRIPT_DIR"

  ln -s "$SCRIPT_DIR/vimrc" "$VIMRC"
  echo "  Linked: $VIMRC → $SCRIPT_DIR/vimrc"

  # Create undo directory (700 to prevent other users reading undo history).
  # Idempotent: only announce when we actually had to create it.
  if [ ! -d "$UNDO_DIR" ]; then
    mkdir -p "$UNDO_DIR"
    chmod 700 "$UNDO_DIR"
    echo "  Created: $UNDO_DIR"
  fi

  INSTALL_OK=1
  echo ""
  echo "iVim installed successfully!"
}

uninstall() {
  echo "Uninstalling iVim..."
  echo ""

  # Remove symlinks (only if they point to our directory)
  if [ -L "$VIM_DIR" ] && [ "$(readlink "$VIM_DIR")" = "$SCRIPT_DIR" ]; then
    rm "$VIM_DIR"
    echo "  Removed: $VIM_DIR symlink"

    local backup
    backup="$(find_latest_backup "$VIM_DIR")"
    if [ -n "$backup" ]; then
      mv "$backup" "$VIM_DIR"
      echo "  Restored: $backup → $VIM_DIR"
    fi
  elif [ -L "$VIM_DIR" ]; then
    echo "  Skipped: $VIM_DIR symlink does not point to iVim"
  else
    echo "  Skipped: $VIM_DIR is not a symlink"
  fi

  if [ -L "$VIMRC" ] && [ "$(readlink "$VIMRC")" = "$SCRIPT_DIR/vimrc" ]; then
    rm "$VIMRC"
    echo "  Removed: $VIMRC symlink"

    local backup
    backup="$(find_latest_backup "$VIMRC")"
    if [ -n "$backup" ]; then
      mv "$backup" "$VIMRC"
      echo "  Restored: $backup → $VIMRC"
    fi
  elif [ -L "$VIMRC" ]; then
    echo "  Skipped: $VIMRC symlink does not point to iVim"
  else
    echo "  Skipped: $VIMRC is not a symlink"
  fi

  # State directories created/used by iVim that may still hold user data
  # (undo history, netrw history). We deliberately do NOT auto-remove
  # them — destroying undo history without consent is too aggressive —
  # but we point them out so the user can clean up if they want.
  local data_dir="$HOME/.local/share/vim"
  if [ -d "$data_dir" ]; then
    echo ""
    echo "  Note: iVim state in $data_dir was left intact (undo history,"
    echo "        netrw bookmarks). Remove manually with:"
    echo "          rm -rf \"$data_dir\""
  fi

  echo ""
  echo "iVim uninstalled."
}

# --- Main ---
case "${1:-}" in
  --uninstall)
    uninstall
    ;;
  --help|-h)
    usage
    ;;
  "")
    install
    ;;
  *)
    echo "Unknown option: $1"
    usage
    exit 1
    ;;
esac
