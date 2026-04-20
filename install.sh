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

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="${target}.bak.${TIMESTAMP}"
    echo "  Backing up: $target → $backup"
    mv "$target" "$backup"
  fi
}

find_latest_backup() {
  local target="$1"
  # Find the most recent .bak.* file by timestamp suffix
  local latest=""
  local latest_ts=0
  # nullglob: an unmatched glob yields zero iterations instead of a literal string
  shopt -s nullglob
  for f in "${target}.bak."*; do
    local ts="${f##*.bak.}"
    if [ "$ts" -gt "$latest_ts" ] 2>/dev/null; then
      latest_ts="$ts"
      latest="$f"
    fi
  done
  shopt -u nullglob
  echo "$latest"
}

install() {
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

  # Create undo directory (700 to prevent other users reading undo history)
  mkdir -p "$UNDO_DIR"
  chmod 700 "$UNDO_DIR"
  echo "  Created: $UNDO_DIR"

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
