export PATH="$HOME/.npm-global/bin:$PATH"
if [ -d /opt/homebrew/opt/python@3.13/libexec/bin ]; then
  export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"
fi
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export EDITOR="nvim"
export VISUAL="nvim"
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi
