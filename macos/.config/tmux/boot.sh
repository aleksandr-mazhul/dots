#!/usr/bin/env bash
# Ensure a tmux server exists, restoring the last resurrect snapshot first.
# Replaces continuum's auto-restore, which silently skips when any other tmux
# process is around at start (e.g. two Kittys) — autosave then overwrote `last`
# with an empty session. flock serialises concurrent Kitty windows.
set -uo pipefail

SELF="$(/usr/bin/readlink -f "${BASH_SOURCE[0]}")"
SELF_DIR="$(dirname "$SELF")"
# shellcheck source=./portable.sh
source "$SELF_DIR/portable.sh"

exec 9>"$RUNBASE/tmux-boot.lock"
portable_flock 9

tmux has-session 2>/dev/null && exit 0

if command -v systemd-run >/dev/null 2>&1; then
  # Own scope, ordered Before=tmux-save.service, so on shutdown systemd runs the
  # final save BEFORE it SIGTERMs the server: stop order is the reverse of start
  # order, so the unit that starts first stops last. (After= here is the trap: it
  # reads right but kills the server first -- verified with dummy units.) Started
  # bare, the server lands in the launching Kitty's scope, which has no ordering
  # against tmux-save.service: both stop in parallel and the save races a dying
  # server. Pane scopes (tmux-spawn-*) are stopped before the server's scope by
  # tmux itself, so the chain is: save -> server -> panes. Fallback: a bare
  # server beats no server.
  # 9>&- : the daemonised server must not inherit (and forever hold) the lock fd
  systemd-run --user --scope --quiet --unit=tmux-server -p Before=tmux-save.service \
    tmux new-session -d -s 0 9>&- 2>/dev/null \
    || tmux has-session 2>/dev/null \
    || tmux new-session -d -s 0 9>&- || exit 0
else
  # macOS: no systemd, and no shutdown-ordering unit to protect (the launchd
  # agent is interval-based, not shutdown-triggered -- see the LaunchAgent
  # plist). Same fallback chain, minus the scope/ordering step: try to start
  # the server, re-check for a session that raced in from a concurrent
  # boot.sh, try once more bare, otherwise give up cleanly.
  # 9>&- : the daemonised server must not inherit (and forever hold) the lock fd
  tmux new-session -d -s 0 9>&- 2>/dev/null \
    || tmux has-session 2>/dev/null \
    || tmux new-session -d -s 0 9>&- || exit 0
fi
restore="$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"
last="$HOME/.local/share/tmux/resurrect/last"
# run-shell (not a direct call): restore.sh derives the socket from $TMUX, which is empty outside tmux.
[[ -x "$restore" && -e "$last" ]] && tmux run-shell "$restore" >/dev/null 2>&1 9>&-

# Attach target = session that was focused when the snapshot was taken.
target="$(awk -F'\t' '$1=="state"{print $2; exit}' "$last" 2>/dev/null)"
if [[ -n "$target" ]] && tmux has-session -t "=$target" 2>/dev/null; then
  printf '%s\n' "$target" >"$RUNBASE/tmux-boot-target"
else
  rm -f "$RUNBASE/tmux-boot-target"
fi
exit 0
