#!/usr/bin/env bash
# Coalescing wrapper around tmux-resurrect's save.sh.
#
#   tmux-save.sh request   from tmux hooks; returns in ~4 ms, coalesces bursts
#   tmux-save.sh now       save as soon as the lock is free (detach / manual)
#   tmux-save.sh quiet     what continuum passes via @resurrect-save-script-path,
#                          so the periodic tick shares this lock too
#
# EVERY save must go through here. Two resurrect bugs make that mandatory; both
# were reproduced on tmux 3.7c / resurrect cff343c:
#
#   1. save.sh takes no lock at all. Two overlapping saves append into the same
#      state file and stage into the same pane_contents/ dir, which each one rm's
#      at the end -> duplicated `pane` lines, 3 `state` lines, truncated tar.gz.
#
#   2. Worse, and silent: save.sh names its output from `date +%Y%m%dT%H%M%S`,
#      i.e. 1-second granularity. Two saves in the SAME SECOND write the same
#      path, then files_differ compares that file against `last` -- a symlink to
#      that same inode -- decides "unchanged" and rm's it. `last` is left
#      dangling, boot.sh's `-e "$last"` guard fails, and the restore is skipped
#      in silence. Hence the >=1s floor and the self-heal below.
#
# Debug: TMUX_SAVE_LOG=/path/to/log to trace decisions.
#
# --- macOS portability (this file is shared with Linux; see portable.sh) ------
# macOS has no GNU stat, no flock(1), no setsid(1). portable.sh picks working
# replacements ONCE (by capability probe), and everything below calls only the
# portable names (mtime / detach_exec / portable_flock), never the raw tools.
set -uo pipefail

SELF="$(/usr/bin/readlink -f "${BASH_SOURCE[0]}")"
SELF_DIR="$(dirname "$SELF")"
# shellcheck source=./portable.sh
source "$SELF_DIR/portable.sh"

DEBOUNCE="${TMUX_SAVE_DEBOUNCE:-4}"   # quiet seconds before a save
MAXWAIT="${TMUX_SAVE_MAXWAIT:-30}"    # force a save after this much nonstop churn
INHIBIT_TTL=300                       # a forgotten restore-inhibit expires

RUN="$RUNBASE/tmux-save-$(id -u)"
STAMP="$RUN/dirty"
WORKER_LOCK="$RUN/worker.lock"
SAVE_LOCK="$RUN/save.lock"
LASTRUN="$RUN/lastrun"
INHIBIT="$RUN/inhibit"

SAVE="$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"

mkdir -p "$RUN" 2>/dev/null || exit 0
[ -x "$SAVE" ] || exit 0
command -v tmux >/dev/null || exit 0

log() { [ -n "${TMUX_SAVE_LOG:-}" ] && printf '%s %s\n' "$(date +%H:%M:%S)" "$*" >>"$TMUX_SAVE_LOG"; return 0; }

inhibited() {
  [ -e "$INHIBIT" ] || return 1
  if [ $(( $(date +%s) - $(mtime "$INHIBIT") )) -gt "$INHIBIT_TTL" ]; then
    rm -f "$INHIBIT"; return 1
  fi
  return 0
}

# No eval here: expand a leading ~ by hand rather than executing an option value.
resurrect_dir() {
  local d
  d="$(tmux show-option -gqv @resurrect-dir 2>/dev/null)"
  [ -n "$d" ] || d="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
  case "$d" in
    "~") d="$HOME" ;;
    "~/"*) d="$HOME/${d#\~/}" ;;
  esac
  printf '%s' "$d"
}

# --- macOS deviation ------------------------------------------------------------
# resurrect's `state` line is `#{client_session}` from `tmux display-message
# -p`, which is EMPTY when no client is attached (confirmed empirically: with
# a client attached it holds the session name; with none attached it is the
# empty string). On Linux the only saves that ran fully detached were the
# client-detached hook (right at detach -- the OLD good target from the
# still-live previous snapshot was already what boot.sh needed next boot,
# since continuum's periodic ticks only run while a client is attached and
# draws status-right) and the shutdown unit. On macOS, launchd's worker-now
# runs the periodic save every 60s regardless of attach state, so every one
# of those ticks while fully detached would silently blank out the
# last-focused-session target that boot.sh relies on. Fix it after each save:
# if no client is attached AND the fresh snapshot's own state-session field
# came back empty AND the previously remembered target session still exists,
# rewrite just that field back to the previous target, in place (temp file +
# mv over the file `last` already points to, so `last` stays a valid symlink
# throughout).
# resurrect only keeps a new snapshot when `cmp` says it differs from `last`.
# The empty state field always differs from the filled-in one, so without the
# dedup below every detached tick would keep a new file (~1440/day; resurrect
# prunes only after 30 days). If the filled-in snapshot is byte-identical to
# the previous one, point `last` back at the previous file and drop the new one.
fill_in_target() {
  local last="$1" prev_target="$2" prev_snap="$3"
  [ -n "$prev_target" ] || return 0
  [ -L "$last" ] && [ -e "$last" ] || return 0

  # A client is attached -> resurrect's own value is authoritative, leave it.
  [ -z "$(tmux list-clients 2>/dev/null)" ] || return 0

  local snapshot cur_target
  snapshot="$(/usr/bin/readlink -f "$last")" || return 0
  [ -n "$snapshot" ] && [ -e "$snapshot" ] || return 0
  cur_target="$(awk -F'\t' '$1=="state"{print $2; exit}' "$snapshot" 2>/dev/null)"
  [ -z "$cur_target" ] || return 0   # already has a real target, don't touch it

  tmux has-session -t "=$prev_target" 2>/dev/null || return 0

  # Plain redirect, not mktemp: keep resurrect's umask-based file mode.
  local tmp="$snapshot.tmp.$$"
  if awk -F'\t' -v OFS='\t' -v t="$prev_target" \
       '$1=="state"{$2=t} {print}' "$snapshot" >"$tmp" 2>/dev/null; then
    mv "$tmp" "$snapshot" && log "state target restored to $prev_target (no client attached)"
  else
    rm -f "$tmp"; return 0
  fi

  if [ -n "$prev_snap" ] && [ "$prev_snap" != "$snapshot" ] && [ -e "$prev_snap" ] \
     && cmp -s "$snapshot" "$prev_snap"; then
    ln -fs "$(basename "$prev_snap")" "$last" && rm -f "$snapshot" \
      && log "unchanged after fill-in -- kept $(basename "$prev_snap")"
  fi
}

do_save() {
  exec 9>"$SAVE_LOCK"
  portable_flock -w 120 9 || { log "lock timeout"; return 0; }
  inhibited && { log "inhibited (restore in flight)"; return 0; }

  # Shutdown guard: never replace a good snapshot with a dead or empty server.
  local panes
  panes="$(tmux list-panes -a -F x 2>/dev/null | wc -l)"
  [ "${panes:-0}" -ge 1 ] || { log "skip: no panes (server gone?)"; return 0; }

  # Bug 2 floor: never two saves inside one wall-clock second.
  [ "$(date +%s)" -le "$(cat "$LASTRUN" 2>/dev/null || echo 0)" ] && sleep 1

  # Remember the currently-recorded target BEFORE saving (macOS deviation,
  # see fill_in_target above): once this save's own state line comes back
  # empty because nothing is attached, this is what we fall back to.
  local prev_last prev_target="" prev_snap=""
  prev_last="$(resurrect_dir)/last"
  if [ -e "$prev_last" ]; then
    prev_target="$(awk -F'\t' '$1=="state"{print $2; exit}' "$prev_last" 2>/dev/null)"
    prev_snap="$(/usr/bin/readlink -f "$prev_last")"
  fi

  "$SAVE" quiet >/dev/null 2>&1
  date +%s >"$LASTRUN"
  log "saved ($panes panes)"

  # Self-heal: if `last` is dangling anyway, redo it a second later.
  local last
  last="$(resurrect_dir)/last"
  if [ -L "$last" ] && [ ! -e "$last" ]; then
    log "last was dangling -- re-saving"
    sleep 1
    "$SAVE" quiet >/dev/null 2>&1
    date +%s >"$LASTRUN"
  fi

  # Never let an unparseable snapshot become `last` (a non-UTF-8 command client
  # turns every tab into `_`): drop it and point `last` back at the old one.
  local new_snap
  new_snap="$(/usr/bin/readlink -f "$last")"
  if [ -n "$prev_snap" ] && [ -e "$prev_snap" ] && [ "$new_snap" != "$prev_snap" ] \
     && ! grep -q "^pane$(printf '\t')" "$new_snap" 2>/dev/null; then
    ln -fs "$(basename "$prev_snap")" "$last" && rm -f "$new_snap"
    log "no parseable pane lines -- dropped $(basename "$new_snap")"
    return 0
  fi

  fill_in_target "$last" "$prev_target" "$prev_snap"
}

request() {
  inhibited && exit 0
  : >"$STAMP"
  detach_exec "$SELF" worker
  exit 0
}

case "${1:-request}" in
  now)
    inhibited && exit 0
    detach_exec "$SELF" worker-now
    ;;
  worker-now) do_save ;;
  worker)
    exec 8>"$WORKER_LOCK"
    portable_flock -n 8 || exit 0   # a worker is already pending; it will see our stamp
    deadline=$(( $(date +%s) + MAXWAIT ))
    while :; do
      seen="$(mtime "$STAMP")"
      sleep "$DEBOUNCE"
      inhibited && exit 0
      [ "$(mtime "$STAMP")" = "$seen" ] && break
      [ "$(date +%s)" -ge "$deadline" ] && { log "maxwait hit"; break; }
    done
    # Release before saving: a request that lands mid-save must be able to
    # start the next worker, or that change waits for the next continuum tick.
    exec 8>&-
    do_save
    ;;
  *) request ;;
esac
exit 0
