#!/bin/bash
# Install Kanata as a LaunchDaemon and stop Karabiner-Elements grabber.
# Asks for an admin password via macOS GUI.
set -euo pipefail

DOTFILES_KANATA="${HOME}/dotfiles/macos/.config/kanata"
if [[ -x "${HOME}/.cargo/bin/kanata" ]]; then
  KANATA_BIN_SRC="${HOME}/.cargo/bin/kanata"
elif [[ -x /opt/homebrew/bin/kanata ]]; then
  KANATA_BIN_SRC="/opt/homebrew/bin/kanata"
elif [[ -x /usr/local/bin/kanata ]]; then
  KANATA_BIN_SRC="/usr/local/bin/kanata"
else
  echo "kanata binary not found. Install it with brew or cargo, then rerun." >&2
  exit 1
fi

RENDERED_KANATA_PLIST="$(mktemp)"
sed "s|__HOME__|${HOME}|g" "${DOTFILES_KANATA}/plist/dev.kanata.kanata.plist" > "$RENDERED_KANATA_PLIST"
trap 'rm -f "$RENDERED_KANATA_PLIST"' EXIT

"${DOTFILES_KANATA}/scripts/build-media-key.sh"

osascript <<APPLESCRIPT
do shell script "
set -euo pipefail

# Stop Homebrew kanata if it was registered
launchctl bootout system/homebrew.mxcl.kanata 2>/dev/null || true
launchctl bootout gui/\$(id -u)/homebrew.mxcl.kanata 2>/dev/null || true

# Install kanata binary
mkdir -p /usr/local/bin
cp '${KANATA_BIN_SRC}' /usr/local/bin/kanata
chmod 755 /usr/local/bin/kanata
xattr -dr com.apple.quarantine /usr/local/bin/kanata 2>/dev/null || true

# VirtualHID daemon: keep the one Karabiner-Elements already registered
# (org.pqrs.service.daemon.Karabiner-VirtualHIDDevice-Daemon). Only install
# a fallback plist if that service is not running.
if ! launchctl print system/org.pqrs.service.daemon.Karabiner-VirtualHIDDevice-Daemon >/dev/null 2>&1; then
  cp '${DOTFILES_KANATA}/plist/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist' /Library/LaunchDaemons/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist
  chown root:wheel /Library/LaunchDaemons/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist
  chmod 644 /Library/LaunchDaemons/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist
  launchctl bootstrap system /Library/LaunchDaemons/org.pqrs.Karabiner-VirtualHIDDevice-Daemon.plist
  launchctl enable system/org.pqrs.Karabiner-VirtualHIDDevice-Daemon
  launchctl kickstart -k system/org.pqrs.Karabiner-VirtualHIDDevice-Daemon
fi

# Keep Karabiner grabber from coming back after login (VirtualHID stays)
cp '${DOTFILES_KANATA}/scripts/disable-karabiner-grabber.sh' /usr/local/libexec/disable-karabiner-grabber.sh
chmod 755 /usr/local/libexec/disable-karabiner-grabber.sh
cp '${DOTFILES_KANATA}/plist/dev.kanata.disable-karabiner.plist' /Library/LaunchDaemons/dev.kanata.disable-karabiner.plist
chown root:wheel /Library/LaunchDaemons/dev.kanata.disable-karabiner.plist
chmod 644 /Library/LaunchDaemons/dev.kanata.disable-karabiner.plist
launchctl bootout system/dev.kanata.disable-karabiner 2>/dev/null || true
launchctl bootstrap system /Library/LaunchDaemons/dev.kanata.disable-karabiner.plist
launchctl enable system/dev.kanata.disable-karabiner
launchctl kickstart -k system/dev.kanata.disable-karabiner

# Kanata daemon
cp '${RENDERED_KANATA_PLIST}' /Library/LaunchDaemons/dev.kanata.kanata.plist
chown root:wheel /Library/LaunchDaemons/dev.kanata.kanata.plist
chmod 644 /Library/LaunchDaemons/dev.kanata.kanata.plist
launchctl bootout system/dev.kanata.kanata 2>/dev/null || true
launchctl bootstrap system /Library/LaunchDaemons/dev.kanata.kanata.plist
launchctl enable system/dev.kanata.kanata
launchctl kickstart -k system/dev.kanata.kanata

# Activate DriverKit extension if needed
/Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager forceActivate 2>/dev/null || true
" with administrator privileges
APPLESCRIPT

echo "Daemons installed. Check: sudo launchctl print system/dev.kanata.kanata"
echo "Logs: /var/log/kanata.log"
echo "If keys do nothing: System Settings → Privacy & Security → Input Monitoring"
echo "and Accessibility — add /usr/local/bin/kanata, then rerun this script."
