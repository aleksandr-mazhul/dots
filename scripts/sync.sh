#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
cd "$DOTFILES"
# shellcheck source=lib/host-package.sh
source "$DOTFILES/scripts/lib/host-package.sh"

echo "Pulling latest changes..."
git pull --rebase --autostash

echo "Re-stowing packages..."
stow -R common

case "$(uname -s)" in
  Darwin)
    stow -R macos
    ;;
  Linux)
    stow -R linux
    ;;
esac

stow_host_package restow

echo "Sync complete."
