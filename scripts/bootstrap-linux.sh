#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
cd "$DOTFILES"
# shellcheck source=lib/host-package.sh
source "$DOTFILES/scripts/lib/host-package.sh"

echo "Installing GNU Stow..."
"$DOTFILES/scripts/install-stow.sh"

echo "Linking dotfiles with GNU Stow..."
stow common
stow linux
stow_host_package stow

cat <<'EOF'

Bootstrap linked common/ and linux/ into $HOME.
It does not install distro packages. You still want zsh, neovim, tmux,
kitty, and kanata from the distro, then:

  systemctl --user enable --now kanata.service

Reload the shell: exec $SHELL
EOF
