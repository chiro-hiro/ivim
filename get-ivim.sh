#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  printf '\033[31m\033[1merror:\033[0m Do not run this script as root or with sudo.\n' >&2
  exit 1
fi

# iVim online installer
# Usage: curl -fsSL https://raw.githubusercontent.com/chiro-hiro/ivim/master/get-ivim.sh | bash
#    or: curl -fsSL https://raw.githubusercontent.com/chiro-hiro/ivim/master/get-ivim.sh | bash -s -- --uninstall

IVIM_DIR="$HOME/.ivim"
VIM_DIR="$HOME/.vim"
VIMRC="$HOME/.vimrc"
UNDO_DIR="$HOME/.local/share/vim/undodir"
REPO="https://github.com/chiro-hiro/ivim.git"
TIMESTAMP="$(date +%s)"

# --- Colors ---
BOLD='\033[1m'
GREEN='\033[32m'
BLUE='\033[34m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

info()  { printf '%s%sinfo:%s %s\n' "$BLUE" "$BOLD" "$RESET" "$1"; }
ok()    { printf '%s%s  ok:%s %s\n' "$GREEN" "$BOLD" "$RESET" "$1"; }
warn()  { printf '%s%swarn:%s %s\n' "$YELLOW" "$BOLD" "$RESET" "$1"; }
err()   { printf '%s%serror:%s %s\n' "$RED" "$BOLD" "$RESET" "$1" >&2; }

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="${target}.bak.${TIMESTAMP}"
    warn "Backing up $target → $backup"
    mv "$target" "$backup"
  fi
}

find_latest_backup() {
  local target="$1"
  local latest=""
  local latest_ts=0
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

check_deps() {
  local missing=()
  for cmd in git vim; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    err "Missing required tools: ${missing[*]}"
    exit 1
  fi
}

install() {
  printf "\n"
  printf "${BOLD}${BLUE}  _ ${GREEN}__   __ ${BLUE}_ ${GREEN}            ${RESET}\n"
  printf "${BOLD}${BLUE} (_)${GREEN}\\ \\ / /${BLUE}(_)${GREEN}_ __ ___  ${RESET}\n"
  printf "${BOLD}${BLUE} | | ${GREEN}\\ V / ${BLUE}| | ${GREEN}'_ \` _ \\ ${RESET}\n"
  printf "${BOLD}${BLUE} | |  ${GREEN}\\_/  ${BLUE}| | ${GREEN}| | | | |${RESET}\n"
  printf "${BOLD}${BLUE} |_|       ${BLUE}|_|${GREEN}_| |_| |_|${RESET}\n"
  printf "\n"
  printf "${BOLD}  Plugin-free Vim with Tokyo Night${RESET}\n"
  printf "\n"

  info "Checking dependencies..."
  check_deps
  ok "git and vim found"

  # Clone or update
  if [ -d "$IVIM_DIR" ]; then
    info "Updating existing installation..."
    local remote
    remote="$(git -C "$IVIM_DIR" remote get-url origin 2>/dev/null || echo "")"
    if [ "$remote" != "$REPO" ]; then
      err "$IVIM_DIR exists but remote does not match expected repo"
      err "Expected: $REPO"
      err "Got:      $remote"
      exit 1
    fi
    git -C "$IVIM_DIR" pull --ff-only --quiet
    ok "Updated $IVIM_DIR"
  else
    info "Cloning iVim..."
    if ! git clone --quiet "$REPO" "$IVIM_DIR"; then
      rm -rf "$IVIM_DIR" 2>/dev/null || true
      err "Clone failed, cleaned up partial download"
      exit 1
    fi
    ok "Cloned to $IVIM_DIR"
  fi

  # Backup existing config
  info "Setting up Vim config..."
  backup_if_exists "$VIM_DIR"
  backup_if_exists "$VIMRC"

  # Symlink
  ln -s "$IVIM_DIR" "$VIM_DIR"
  ok "Linked $VIM_DIR → $IVIM_DIR"

  ln -s "$IVIM_DIR/vimrc" "$VIMRC"
  ok "Linked $VIMRC → $IVIM_DIR/vimrc"

  # Undo directory (700 to prevent other users reading undo history)
  mkdir -p "$UNDO_DIR"
  chmod 700 "$UNDO_DIR"
  ok "Created $UNDO_DIR"

  printf "\n"
  printf "${GREEN}${BOLD}iVim installed successfully!${RESET}\n"
  printf "\n"
  printf "  Run ${BOLD}vim${RESET} to get started.\n"
  printf "  Uninstall: ${BOLD}curl -fsSL <install-url> | bash -s -- --uninstall${RESET}\n"
  printf "\n"
}

uninstall() {
  info "Uninstalling iVim..."

  if [ -L "$VIM_DIR" ] && [ "$(readlink "$VIM_DIR")" = "$IVIM_DIR" ]; then
    rm "$VIM_DIR"
    ok "Removed $VIM_DIR symlink"
    local backup
    backup="$(find_latest_backup "$VIM_DIR")"
    if [ -n "$backup" ]; then
      mv "$backup" "$VIM_DIR"
      ok "Restored $backup"
    fi
  elif [ -L "$VIM_DIR" ]; then
    warn "$VIM_DIR symlink does not point to iVim, skipping"
  elif [ -e "$VIM_DIR" ]; then
    warn "$VIM_DIR is not a symlink, skipping"
  fi

  if [ -L "$VIMRC" ] && [ "$(readlink "$VIMRC")" = "$IVIM_DIR/vimrc" ]; then
    rm "$VIMRC"
    ok "Removed $VIMRC symlink"
    local backup
    backup="$(find_latest_backup "$VIMRC")"
    if [ -n "$backup" ]; then
      mv "$backup" "$VIMRC"
      ok "Restored $backup"
    fi
  elif [ -L "$VIMRC" ]; then
    warn "$VIMRC symlink does not point to iVim, skipping"
  elif [ -e "$VIMRC" ]; then
    warn "$VIMRC is not a symlink, skipping"
  fi

  if [ -d "$IVIM_DIR" ] && [ ! -L "$IVIM_DIR" ]; then
    # Guard against losing uncommitted/unpushed local work
    local dirty=""
    if [ -d "$IVIM_DIR/.git" ]; then
      if [ -n "$(git -C "$IVIM_DIR" status --porcelain 2>/dev/null)" ]; then
        dirty="uncommitted changes"
      elif [ -n "$(git -C "$IVIM_DIR" log '@{u}..HEAD' --oneline 2>/dev/null)" ]; then
        dirty="unpushed commits"
      fi
    fi
    if [ -n "$dirty" ]; then
      err "$IVIM_DIR has $dirty — not removing."
      err "Commit or push your work, or delete $IVIM_DIR manually."
      exit 1
    fi
    rm -rf "$IVIM_DIR"
    ok "Removed $IVIM_DIR"
  elif [ -L "$IVIM_DIR" ]; then
    warn "$IVIM_DIR is a symlink, not removing for safety"
  fi

  printf "\n"
  printf "${GREEN}${BOLD}iVim uninstalled.${RESET}\n"
  printf "\n"
}

# --- Main ---
case "${1:-}" in
  --uninstall)
    uninstall
    ;;
  --help|-h)
    printf "Usage:\n"
    printf "  Install:   curl -fsSL <url> | bash\n"
    printf "  Uninstall: curl -fsSL <url> | bash -s -- --uninstall\n"
    ;;
  "")
    install
    ;;
  *)
    err "Unknown option: $1"
    exit 1
    ;;
esac
