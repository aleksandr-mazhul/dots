#!/usr/bin/env bash
set -euo pipefail

DOTFILES="${DOTFILES:-$HOME/dotfiles}"
cd "$DOTFILES"
# shellcheck source=lib/host-package.sh
source "$DOTFILES/scripts/lib/host-package.sh"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required before bootstrap." >&2
  echo "Install it from https://brew.sh, then run this script again." >&2
  exit 1
fi

echo "Installing GNU Stow..."
"$DOTFILES/scripts/install-stow.sh"

echo "Installing Homebrew packages..."
brew bundle --file="$DOTFILES/common/Brewfile"

echo "Linking dotfiles with GNU Stow..."
stow common
stow macos
stow_host_package stow

cat <<EOF

Bootstrap linked this repo into \$HOME and installed the Brewfile.
Reload the shell: exec \$SHELL

macOS still asks for these by hand. A script cannot grant them:

  1. System Settings → Privacy & Security → Accessibility
     Enable yabai, skhd, and SketchyBar.
  2. Load the yabai scripting addition (admin password):
     sudo yabai --load-sa
  3. Keyboard layout, after Kanata is installed:
     $DOTFILES/macos/.config/kanata/scripts/install-daemon.sh

Secrets are not in git. Copy private/ onto the machine yourself
(GitHub CLI login, Copilot auth, ~/.zsh.private).

Screenshot watching still uses /Users/alexandermazhul/screenshots
in macos/Library/LaunchAgents/com.alexandermazhul.screenshot-clipboard.plist.
EOF
