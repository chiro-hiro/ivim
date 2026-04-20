# iVim terminal — Tokyo Night prompt

# Prevent infinite recursion if ~/.bashrc ends up sourcing us back.
# Deliberately NOT exported: the guard only needs to protect the current
# bash process from re-sourcing itself during ~/.bashrc loading. Exporting
# would leak the flag to every child process the user spawns, which
# subprocesses could introspect to detect the iVim terminal context.
if [ -n "${_IVIM_TERMINAL_SOURCED:-}" ]; then
  return 0 2>/dev/null || exit 0
fi
_IVIM_TERMINAL_SOURCED=1

# Resolve git's absolute path BEFORE sourcing /etc/profile or ~/.bashrc so
# PATH manipulation in those files cannot substitute a malicious git binary
# that would then be invoked on every prompt redraw.
_IVIM_GIT="$(command -v git 2>/dev/null || echo git)"

# Source system and user profile for full environment
[ -f /etc/profile ] && source /etc/profile
[ -f ~/.bashrc ] && source ~/.bashrc

# Tokyo Night prompt
# Green: user | Cyan: host | Blue: directory | Purple: git branch | Purple: prompt
__tn_git_branch() {
  local branch
  branch="$("$_IVIM_GIT" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  [ -z "$branch" ] && return
  if [ "$branch" = "HEAD" ]; then
    # Detached HEAD — show short SHA
    branch="$("$_IVIM_GIT" rev-parse --short HEAD 2>/dev/null)"
    branch="detached:${branch}"
  fi
  printf ' \001\e[35m\002 %s\001\e[0m\002' "$branch"
}

PS1='\[\e[32m\]\u\[\e[0m\]@\[\e[36m\]\h \[\e[34m\]\w\[\e[0m\]$(__tn_git_branch) \[\e[35m\]❯\[\e[0m\] '
