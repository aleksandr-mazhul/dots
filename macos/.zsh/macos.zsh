# --- Homebrew ---
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- Homebrew-installed shell plugins ---
brew_share="/opt/homebrew/share"
[[ -f "$brew_share/powerlevel10k/powerlevel10k.zsh-theme" ]] && source "$brew_share/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f "$brew_share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$brew_share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[[ -f "$brew_share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$brew_share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
unset brew_share

# --- SSH agent ---
if [ -z "$SSH_AUTH_SOCK" ]; then
  mkdir -p "$HOME/.ssh"
  RUNNING_AGENT="$(ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]')"
  if [ "$RUNNING_AGENT" = "0" ]; then
    ssh-agent -s &> "$HOME/.ssh/ssh-agent"
  fi
  eval "$(cat "$HOME/.ssh/ssh-agent")"
fi
