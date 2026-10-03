#!/usr/bin/env bash

# signals.sh - Yabai event signal handlers
# Defines event-driven behaviors for window focus, application launch, etc.

set -e

remove_all_signals() {
  local i count
  count="$(yabai -m signal --list 2>/dev/null | jq 'length' 2>/dev/null || echo 0)"
  [[ "$count" =~ ^[0-9]+$ ]] || count=0
  for ((i = count - 1; i >= 0; i--)); do
    yabai -m signal --remove "$i" 2>/dev/null || true
  done
}

remove_all_signals

AUTOSTART_LOCK="/tmp/yabai.$(whoami).autostart"

# Restore SA after Dock restart. yabairc adds this first, then this file
# clears all signals, so it must be re-registered here.
yabai -m signal --add event=dock_did_restart label=sa_dock action="sudo yabai --load-sa" 2>/dev/null || true

# Cheap bar updates. Full sketchybar --reload is owned by yabairc once.
yabai -m signal --add event=window_focused label=bar_window_focus action="sketchybar --trigger window_focus 2>/dev/null || true" 2>/dev/null || true
yabai -m signal --add event=window_created label=bar_window_created action="sketchybar --trigger window_focus 2>/dev/null; sketchybar --trigger space_windows_change 2>/dev/null || true" 2>/dev/null || true
yabai -m signal --add event=window_destroyed label=bar_window_destroyed action="sketchybar --trigger space_windows_change 2>/dev/null || true" 2>/dev/null || true

# Follow new windows during interactive use, but not while session-startup
# is flooding workspaces. That focus-storm looks like the bar/WM reloading.
yabai -m signal --add event=window_created label=follow_window_created action='
if [[ -f "'"$AUTOSTART_LOCK"'" ]]; then
  exit 0
fi

WINDOW_JSON=$(yabai -m query --windows --window "$YABAI_WINDOW_ID" 2>/dev/null) || exit 0

APP=$(echo "$WINDOW_JSON" | jq -r ".app")
FLOATING=$(echo "$WINDOW_JSON" | jq -r ".\"is-floating\"")
ROLE=$(echo "$WINDOW_JSON" | jq -r ".role")
SUBROLE=$(echo "$WINDOW_JSON" | jq -r ".subrole")
SPACE=$(echo "$WINDOW_JSON" | jq -r ".space")

FOLLOW=false

# normal managed windows
if [[ "$FLOATING" == "false" && "$ROLE" == "AXWindow" && "$SUBROLE" == "AXStandardWindow" ]]; then
  FOLLOW=true
fi

# floating apps we still want to follow
if [[ "$APP" =~ ^(Books|Weather|Wolfram)$ ]]; then
  FOLLOW=true
fi

if [[ "$FOLLOW" == "true" ]]; then
  yabai -m space --focus "$SPACE"
  yabai -m window "$YABAI_WINDOW_ID" --focus
fi
' 2>/dev/null || true

# Telegram restores onto the focused space after window_created. Re-apply the
# workspace a moment later so macOS Restore does not win.
yabai -m signal --add event=window_created app="^Telegram$" label=place_telegram action='
( sleep 0.4; yabai -m window "$YABAI_WINDOW_ID" --space T ) >/dev/null 2>&1 &
' 2>/dev/null || true
yabai -m signal --add event=window_created app="^(WezTerm|wezterm-gui|kitty)$" label=place_terminal action='
( sleep 0.4; yabai -m window "$YABAI_WINDOW_ID" --space Z ) >/dev/null 2>&1 &
' 2>/dev/null || true

# Signal: Ensure new windows respect sublayer rules

yabai -m signal --add event=mission_control_enter label=opacity_mc_enter action="yabai -m config normal_window_opacity 1.0" 2>/dev/null || true
yabai -m signal --add event=mission_control_exit label=opacity_mc_exit action="yabai -m config active_window_opacity 1.0" 2>/dev/null || true
yabai -m signal --add event=display_added label=bar_display_added action="sleep 0.5 && sketchybar --trigger display_change 2>/dev/null || true" 2>/dev/null || true
yabai -m signal --add event=display_removed label=bar_display_removed action="sleep 0.5 && sketchybar --trigger display_change 2>/dev/null || true" 2>/dev/null || true

exit 0
