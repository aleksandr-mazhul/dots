HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=1000

setopt share_history
setopt inc_append_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_expire_dups_first
setopt hist_verify

bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey -r '^[c'
bindkey '^I' expand-or-complete
