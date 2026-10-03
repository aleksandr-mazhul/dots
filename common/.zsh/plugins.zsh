# --- Powerlevel10k ---
# Theme is sourced per-platform (macos.zsh / linux.zsh) since install paths differ.
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# --- FZF ---
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
elif [ -n "${HOMEBREW_PREFIX:-}" ] && [ -f "${HOMEBREW_PREFIX}/opt/fzf/shell/key-bindings.zsh" ]; then
  source "${HOMEBREW_PREFIX}/opt/fzf/shell/key-bindings.zsh"
  [ -f "${HOMEBREW_PREFIX}/opt/fzf/shell/completion.zsh" ] && source "${HOMEBREW_PREFIX}/opt/fzf/shell/completion.zsh"
fi
bindkey -r '^[c'
bindkey '^I' expand-or-complete
if (( ${+widgets[fzf-cd-widget]} )); then
  bindkey '^G' fzf-cd-widget
fi

# --- Zoxide ---
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# --- Autosuggestions & Syntax Highlighting ---
# Sourced per-platform (macos.zsh / linux.zsh) since install paths differ.
