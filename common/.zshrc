# Auto-attach tmux in kitty, before p10k instant prompt (exec'ing tmux after
# instant prompt has started would print p10k console-output warnings and
# waste startup work).
[[ -r "$HOME/.zsh/tmux-auto.zsh" ]] && source "$HOME/.zsh/tmux-auto.zsh"

# Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Platform overrides first (sets up brew PATH, etc.)
case "$(uname -s)" in
  Darwin) [[ -r "$HOME/.zsh/macos.zsh" ]] && source "$HOME/.zsh/macos.zsh" ;;
  Linux)  [[ -r "$HOME/.zsh/linux.zsh" ]] && source "$HOME/.zsh/linux.zsh" ;;
esac

for file in \
  "$HOME/.zsh/exports.zsh" \
  "$HOME/.zsh/completion.zsh" \
  "$HOME/.zsh/base.zsh" \
  "$HOME/.zsh/functions.zsh" \
  "$HOME/.zsh/aliases.zsh" \
  "$HOME/.zsh/plugins.zsh"
do
  [[ -r "$file" ]] && source "$file"
done

[[ -r "$HOME/.zsh/host.zsh" ]] && source "$HOME/.zsh/host.zsh"
[[ -r "$HOME/.zsh.private" ]] && source "$HOME/.zsh.private"

# OpenJDK (Homebrew)
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home"
