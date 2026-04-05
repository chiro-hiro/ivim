# iVim terminal — Tokyo Night prompt
# Source system and user profile for full environment
[ -f /etc/profile ] && source /etc/profile
[ -f ~/.bashrc ] && source ~/.bashrc

# Tokyo Night prompt
# Green: user | Cyan: host | Blue: directory | Purple: git branch | Purple: prompt
__tn_git_branch() {
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
  [ -z "$branch" ] && return
  if [ "$branch" = "HEAD" ]; then
    # Detached HEAD — show short SHA
    branch="$(git rev-parse --short HEAD 2>/dev/null)"
    branch="detached:${branch}"
  fi
  printf ' \001\e[35m\002 %s\001\e[0m\002' "$branch"
}

PS1='\[\e[32m\]\u\[\e[0m\]@\[\e[36m\]\h \[\e[34m\]\w\[\e[0m\]$(__tn_git_branch) \[\e[35m\]❯\[\e[0m\] '
