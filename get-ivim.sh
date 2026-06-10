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
# Pin installs to a specific reviewed commit (the "release"). The installer
# script itself is always fetched fresh from master via curl, but it checks out
# this exact config commit — so users get a known-good version, not an arbitrary
# master HEAD. Pin to the immutable SHA (a tag can be force-moved); IVIM_VERSION
# is the human label (tag 0.1.7 also points here). Bump both to ship a release.
IVIM_VERSION="0.1.7"
IVIM_COMMIT="14fa63962bf4158fc56477b8bc3699e3020d5f32"
TIMESTAMP="$(date +%s)"

# --- Colors (ANSI-C quoting: vars contain real ESC bytes, not literal \033) ---
BOLD=$'\033[1m'
GREEN=$'\033[32m'
BLUE=$'\033[34m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
RESET=$'\033[0m'

info()  { printf '%s%sinfo:%s %s\n' "$BLUE" "$BOLD" "$RESET" "$1"; }
ok()    { printf '%s%s  ok:%s %s\n' "$GREEN" "$BOLD" "$RESET" "$1"; }
warn()  { printf '%s%swarn:%s %s\n' "$YELLOW" "$BOLD" "$RESET" "$1"; }
err()   { printf '%s%serror:%s %s\n' "$RED" "$BOLD" "$RESET" "$1" >&2; }

# Track backups so an interrupted install can roll them back (see
# restore_on_failure below).
BACKUPS_MADE=()

backup_if_exists() {
  local target="$1"
  local expected="${2:-}"
  # A target that is already the canonical iVim symlink is not user data — do
  # not back it up. Otherwise a partial re-install (user removed only one of
  # the two symlinks) would move the still-good link into a .bak that a later
  # uninstall could wrongly "restore", orphaning the real pre-iVim config.
  if [ -n "$expected" ] && [ -L "$target" ] \
     && [ "$(readlink "$target")" = "$expected" ]; then
    return
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="${target}.bak.${TIMESTAMP}"
    # Two installs within the same second would otherwise reuse the same
    # backup name and silently clobber the earlier backup.
    local n=1
    while [ -e "$backup" ] || [ -L "$backup" ]; do
      backup="${target}.bak.${TIMESTAMP}.${n}"
      n=$((n + 1))
    done
    warn "Backing up $target → $backup"
    mv "$target" "$backup"
    BACKUPS_MADE+=("$target" "$backup")
  fi
}

restore_on_failure() {
  local exit_code=$?
  if [ "$exit_code" -ne 0 ] && [ "${INSTALL_OK:-0}" -ne 1 ]; then
    local i=0
    while [ "$i" -lt "${#BACKUPS_MADE[@]}" ]; do
      local target="${BACKUPS_MADE[$i]}"
      local backup="${BACKUPS_MADE[$((i + 1))]}"
      if [ ! -e "$target" ] && [ -e "$backup" ]; then
        mv "$backup" "$target" 2>/dev/null && \
          warn "Rolled back $backup → $target"
      fi
      i=$((i + 2))
    done
  fi
}
trap restore_on_failure EXIT INT TERM

find_latest_backup() {
  local target="$1"
  # See install.sh:find_latest_backup for the rationale behind the integer
  # and ownership checks — guards against TOCTOU backup-spoofing on a
  # shared-HOME system.
  local latest=""
  local latest_ts=0
  local latest_ctr=0
  shopt -s nullglob
  for f in "${target}.bak."*; do
    # Suffix is <epoch> or, for same-second collisions, <epoch>.<counter>.
    # Both components must be integers — anything else is a crafted name.
    local suffix="${f##*.bak.}"
    local ts="${suffix%%.*}"
    local ctr="${suffix#*.}"
    [ "$ctr" = "$suffix" ] && ctr=0
    if ! [[ "$ts" =~ ^[0-9]+$ ]] || ! [[ "$ctr" =~ ^[0-9]+$ ]]; then
      continue
    fi
    # Ownership guard — test the link itself, not its target (-O dereferences,
    # so a user's own broken-symlink backup would fail it and never restore).
    if [ -z "$(find "$f" -maxdepth 0 -user "$(id -un)" 2>/dev/null)" ]; then
      continue
    fi
    # Skip a "backup" that is itself a symlink into the iVim source — that is
    # not the user's original config but a good iVim link a buggy older run
    # may have moved aside; restoring it would re-point ~/.vim at the source.
    if [ -L "$f" ]; then
      local resolved
      resolved="$(readlink -f "$f" 2>/dev/null || true)"
      if [ "$resolved" = "$IVIM_DIR" ] || [ "$resolved" = "$IVIM_DIR/vimrc" ]; then
        continue
      fi
    fi
    if [ "$ts" -gt "$latest_ts" ] \
       || { [ "$ts" -eq "$latest_ts" ] && [ "$ctr" -gt "$latest_ctr" ]; }; then
      latest_ts="$ts"
      latest_ctr="$ctr"
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

  local is_update=0

  # Clone or update
  if [ -d "$IVIM_DIR" ]; then
    is_update=1
    info "Updating existing installation..."
    # Distinguish "not a git repo" from "wrong remote" — both otherwise yield
    # an empty remote URL and a misleading mismatch message.
    if ! git -C "$IVIM_DIR" rev-parse --git-dir &>/dev/null; then
      err "$IVIM_DIR exists but is not a git repository."
      err "Remove it and re-run, or move it aside first."
      exit 1
    fi
    local remote
    remote="$(git -C "$IVIM_DIR" remote get-url origin 2>/dev/null || echo "")"
    if [ "$remote" != "$REPO" ]; then
      err "$IVIM_DIR exists but remote does not match expected repo"
      err "Expected: $REPO"
      err "Got:      $remote"
      exit 1
    fi
    if ! git -C "$IVIM_DIR" fetch --quiet origin; then
      err "Could not fetch updates for $IVIM_DIR — check your network and re-run."
      exit 1
    fi
  else
    info "Cloning iVim..."
    if ! git clone --quiet "$REPO" "$IVIM_DIR"; then
      rm -rf "$IVIM_DIR" 2>/dev/null || true
      err "Clone failed, cleaned up partial download"
      exit 1
    fi
  fi

  # Check out the pinned commit (detached HEAD at an immutable SHA — a tag could
  # be force-moved, a commit hash cannot). advice.detachedHead=false silences
  # Git's detached-HEAD notice.
  if ! git -C "$IVIM_DIR" -c advice.detachedHead=false checkout --quiet "$IVIM_COMMIT" 2>/dev/null; then
    err "Could not check out pinned version $IVIM_VERSION ($IVIM_COMMIT)."
    err "Local changes in $IVIM_DIR may be in the way: git -C $IVIM_DIR status"
    exit 1
  fi
  # Integrity: HEAD must be exactly the pinned commit.
  local head
  head="$(git -C "$IVIM_DIR" rev-parse HEAD 2>/dev/null || echo "")"
  if [ "$head" != "$IVIM_COMMIT" ]; then
    err "Integrity check failed for $IVIM_DIR."
    err "Expected $IVIM_COMMIT but HEAD is ${head:-<unknown>}."
    exit 1
  fi
  if [ "$is_update" = 1 ]; then
    ok "Updated $IVIM_DIR to $IVIM_VERSION"
  else
    ok "Cloned iVim $IVIM_VERSION to $IVIM_DIR"
  fi

  # Symlinks: if both already point at $IVIM_DIR this is a re-run for an
  # update and there is nothing to back up or relink — the `git pull`
  # above already picked up the new version. Otherwise (fresh install,
  # half-installed state, user removed one of the symlinks) fall through
  # to the backup + ln dance.
  if [ -L "$VIM_DIR" ] && [ "$(readlink "$VIM_DIR")" = "$IVIM_DIR" ] \
     && [ -L "$VIMRC" ] && [ "$(readlink "$VIMRC")" = "$IVIM_DIR/vimrc" ]; then
    ok "Symlinks already in place"
  else
    info "Setting up Vim config..."
    backup_if_exists "$VIM_DIR" "$IVIM_DIR"
    backup_if_exists "$VIMRC" "$IVIM_DIR/vimrc"

    # -sfn (force + no-dereference) so re-linking is idempotent: a plain
    # `ln -s` onto an existing symlink-to-directory (e.g. a half-installed
    # ~/.vim still pointing at ~/.ivim) would follow the link and create a
    # stray nested link inside the target instead of replacing it. -f only
    # ever removes a symlink here — backup_if_exists has already moved any
    # real file/dir aside, and unlink can't delete a real directory.
    ln -sfn "$IVIM_DIR" "$VIM_DIR"
    ok "Linked $VIM_DIR → $IVIM_DIR"

    ln -sfn "$IVIM_DIR/vimrc" "$VIMRC"
    ok "Linked $VIMRC → $IVIM_DIR/vimrc"
  fi

  # Undo directory (700 to prevent other users reading undo history).
  # Idempotent: only announce when we actually had to create it.
  if [ ! -d "$UNDO_DIR" ]; then
    mkdir -p "$UNDO_DIR"
    chmod 700 "$UNDO_DIR"
    ok "Created $UNDO_DIR"
  fi

  INSTALL_OK=1
  printf "\n"
  if [ "$is_update" = 1 ]; then
    printf "${GREEN}${BOLD}iVim ${IVIM_VERSION} updated successfully!${RESET}\n"
  else
    printf "${GREEN}${BOLD}iVim ${IVIM_VERSION} installed successfully!${RESET}\n"
  fi
  printf "\n"
  printf "  Run ${BOLD}vim${RESET} to get started.\n"
  printf "  Uninstall: ${BOLD}curl -fsSL <install-url> | bash -s -- --uninstall${RESET}\n"
  printf "\n"
}

uninstall() {
  info "Uninstalling iVim..."

  # Guard against losing local work BEFORE touching the symlinks. If we tore
  # down ~/.vim / ~/.vimrc first and only then found ~/.ivim dirty, the abort
  # below would leave a half-uninstalled state: config already reverted to an
  # old backup, but ~/.ivim still present and unrestorable on a re-run.
  if [ -d "$IVIM_DIR" ] && [ ! -L "$IVIM_DIR" ] && [ -d "$IVIM_DIR/.git" ]; then
    local dirty=""
    if [ -n "$(git -C "$IVIM_DIR" status --porcelain 2>/dev/null)" ]; then
      dirty="uncommitted changes"
    else
      # Count commits reachable from HEAD but absent from every origin ref. 0
      # means HEAD is a published commit — a pinned-version checkout (detached
      # HEAD) or a pushed branch — so removing it loses nothing. Non-zero means
      # local commits that were never pushed. Any error → treat as unsafe. This
      # also covers a no-upstream local branch (its commits aren't on origin).
      local ahead
      ahead="$(git -C "$IVIM_DIR" rev-list --count HEAD --not --remotes=origin 2>/dev/null || echo 1)"
      if [ "$ahead" != "0" ]; then
        dirty="local commits not present on origin"
      fi
    fi
    if [ -n "$dirty" ]; then
      err "$IVIM_DIR has $dirty — not removing, and leaving your config in place."
      err "Commit or push your work, or delete $IVIM_DIR manually."
      exit 1
    fi
  fi

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

  # Safe to remove now: the dirty guard above already exited if there was
  # unsaved or unpushed work.
  if [ -d "$IVIM_DIR" ] && [ ! -L "$IVIM_DIR" ]; then
    rm -rf "$IVIM_DIR"
    ok "Removed $IVIM_DIR"
  elif [ -L "$IVIM_DIR" ]; then
    warn "$IVIM_DIR is a symlink, not removing for safety"
  fi

  # State directories created/used by iVim that may still hold user data
  # (undo history, netrw history). We deliberately do NOT auto-remove
  # them — destroying undo history without consent is too aggressive —
  # but we point them out so the user can clean up if they want.
  local data_dir="$HOME/.local/share/vim"
  if [ -d "$data_dir" ]; then
    printf "\n"
    warn "iVim state in $data_dir was left intact (undo history, netrw bookmarks)."
    warn "Remove manually with: rm -rf \"$data_dir\""
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
