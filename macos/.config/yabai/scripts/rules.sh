#!/usr/bin/env bash

set -e

yabai -m rule --remove 2>/dev/null || true

# =============================================================================
# Constants
# =============================================================================

# App -> workspace mapping
declare -A APP_WORKSPACE=(
  ["WebStorm"]="W"
  ["Cursor"]="C"
  ["CLion"]="C"
  ["Arc"]="V"
  ["Safari"]="V"
  ["Yandex"]="D"
  ["Google Chrome"]="G"
  ["ChatGPT"]="X"
  ["WezTerm"]="Z"
  ["wezterm-gui"]="Z"
  ["kitty"]="Z"
  ["Finder"]="E"
  ["Telegram"]="T"
  ["Discord"]="I"
  ["Preview"]="P"
  ["Wolfram"]="Q"
  ["Spotify"]="U"
  ["zoom.us"]="Y"
  ["Notes"]="R"
  ["Mail"]="A"
)

# Apps unmanaged by yabai
declare -a APPS_UNMANAGED=(
  "Voice Memos"
  "Stocks"
  "SF Symbols"
  "Chess"
  "AirPort Utility"
  "ColorSync Utility"
  "Disk Utility"
  "Font Book"
  "Print Centre"
  "Screen Sharing"
  "Stickies"
  "System Information"
  "VoiceOver Utility"
  "Console"
  "Dictionary"
  "Tenorshare 4DDiG"
  "Time Machine"
  "Shortcuts"
  "Voice Memos"
  "TV"
  "Tips"
  "Phone"
  "Magnifier"
  "IPhone Mirroring"
  "Find My"
  "Contacts"
  "Clock"
  "Cleamio"
  "Calendar"
  "AppCleaner"
  "3uTools"
  "Homerow"
  "System Preferences"
  "System Settings"
  "1Password"
  "Raycast"
  "Alfred"
  "Bezel"
  "Windscribe"
  "Bartender"
  "Activity Monitor"
  "Directory Utility"
  "App Store"
  "Calculator"
  "Image Capture"
  "Audio MIDI Setup"
  "Migration Assistant"
  "Books"
  "Weather"
  "BetterDisplay"
)

# JetBrains family
JETBRAINS_APPS='^(CLion|WebStorm|IntelliJ IDEA|PyCharm|GoLand|Rider|RubyMine|PhpStorm|DataGrip|DataSpell|AppCode|RustRover|Aqua|JetBrains Toolbox)$'

# JetBrains windows that should float
declare -a JETBRAINS_FLOAT_PATTERNS=(
  '^Rename$'
  '^Delete$'
  '^Move$'
  '^Copy$'
  '^Find.*'
  '^Replace.*'
  '^Commit.*'

  '^Settings$'
  '^Keyboard Shortcut$'
  '^Preferences$'
  '^Project Structure$'
  '^Plugins$'
  '^Terminal$'
  '^Keymap$'
  '^Appearance$'
  '^Color Scheme$'
  '^Code Style.*'
  '^Inspection.*'
  '^Scopes$'
  '^Templates.*'
  '^Live Templates.*'
  '^File Types$'
  '^Plugins.*'
  '^SDKs$'
  '^Project SDK.*'

  '.*Plugin.*'
  '.*Update.*'
  '^IDE .*'
  '.*Error.*'
  '.*Warning.*'
  '^Notifications$'

  '^New .*'
  '^Open .*'
  '^Create .*'
  '^Select .*'
  '^Choose .*'
  '^Attach .*'
  '^Register .*'
  '^Import .*'
  '^Export .*'
  '^Invalidate .*'

  '^Refactor.*'
  '^Safe Delete.*'
  '^Run.*'
  '^Debug.*'
  '^Edit .*'

  '^Generate.*'
  '^Override.*'
  '^Implement.*'

  '^Rename .*'
  '^Move .*'
  '^Copy .*'
  '^Delete .*'

  '^Git .*'
  '^Merge.*'
  '^Rebase.*'
  '^Cherry-Pick.*'
  '^Push.*'
  '^Pull.*'

  '^Search Everywhere$'
  '^Go to .*'
)

# =============================================================================
# Rules
# =============================================================================

apply_workspace_rules() {
  for app in "${!APP_WORKSPACE[@]}"; do
    yabai -m rule --add \
      app="^${app}$" \
      space="${APP_WORKSPACE[$app]}" 2>/dev/null || true
  done
}

apply_unmanaged_rules() {
  for app in "${APPS_UNMANAGED[@]}"; do
    yabai -m rule --add \
      app="^${app}$" \
      manage=off \
      sticky=off 2>/dev/null || true
  done
}

apply_dialog_rules() {
  yabai -m rule --add title="^(Open|Save|Save As|Export|Import|Preferences|Settings)$" manage=off 2>/dev/null || true
  yabai -m rule --add title=".*(Preferences|Settings|Inspector).*" manage=off 2>/dev/null || true
  yabai -m rule --add title="^(Quick Look)$" manage=off 2>/dev/null || true
  yabai -m rule --add title=".*(Authentication|Login|Sign In).*" manage=off 2>/dev/null || true
}

apply_jetbrains_rules() {
  for pattern in "${JETBRAINS_FLOAT_PATTERNS[@]}"; do
    yabai -m rule --add \
      app="$JETBRAINS_APPS" \
      title="$pattern" \
      manage=off 2>/dev/null || true
  done
}

# =============================================================================
# Main
# =============================================================================

apply_unmanaged_rules
apply_dialog_rules
apply_jetbrains_rules

# Wolfram launcher -> float
yabai -m rule --add \
  app="^Wolfram$" \
  title="^Welcome to Wolfram Mathematica$" \
  manage=off 2>/dev/null || true

apply_workspace_rules

exit 0
