# Shared portability helpers for tmux-save.sh and boot.sh.
#
# macOS (this repo's Darwin target) has no GNU coreutils stat, no flock(1),
# and no setsid(1); Linux (the reference platform) has all three. Rather than
# re-probe on every call, each capability is detected ONCE below and the rest
# of the script always calls the portable wrapper (mtime / detach_exec /
# portable_flock), never the raw command.
#
# Meant to be `source`d, not executed.

# --- runtime dir --------------------------------------------------------------
# Orchestrator decision 1: identical expression everywhere (tmux.conf inhibit
# hooks, tmux-save.sh, boot.sh). launchd starts agents with no $TMPDIR at all,
# so seed it from getconf first -- that returns the same per-user
# /var/folders/.../T/ that a normal login shell already has as $TMPDIR.
[ -n "${TMPDIR:-}" ] || TMPDIR="$(getconf DARWIN_USER_TEMP_DIR 2>/dev/null || echo /tmp)"
export TMPDIR
RUNBASE="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}"

# --- PATH ----------------------------------------------------------------------
# Under launchd, PATH is minimal and homebrew's tmux/perl may not be on it.
# The plist sets EnvironmentVariables PATH too; this is belt-and-braces and
# cheap. Linux is untouched (no such prefix exists there).
case "$(uname -s)" in
  Darwin)
    case ":$PATH:" in
      *:/opt/homebrew/bin:*) ;;
      *) PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" ;;
    esac
    export PATH
    # launchd also starts agents with no locale. A tmux command client without
    # UTF-8 rewrites tabs and non-ASCII in -F / -p output to `_`, so resurrect
    # writes `state_0_` and no parseable pane lines -- a garbage snapshot that
    # still becomes `last`. Seen for real on the first launchd ticks.
    [ -n "${LC_ALL:-}${LC_CTYPE:-}${LANG:-}" ] || export LANG=en_US.UTF-8
    ;;
esac

# --- mtime ----------------------------------------------------------------------
# GNU stat: `stat -c %Y FILE`. BSD/Darwin stat: `stat -f %m FILE`. Chosen once
# by uname, not by trial-and-error on every call.
case "$(uname -s)" in
  Darwin) _STAT_ARGS=(-f "%m") ;;
  *)      _STAT_ARGS=(-c "%Y") ;;
esac
mtime() { stat "${_STAT_ARGS[@]}" "$1" 2>/dev/null || echo 0; }

# --- detached background exec (setsid -f replacement) ---------------------------
# `setsid -f CMD...`: fork, parent returns immediately, child starts a new
# session (detached from the caller's session/controlling terminal) and execs
# CMD. Where setsid(1) is missing, a perl one-liner does the same: fork once,
# parent exits at once (so the caller's `detach_exec` call returns fast),
# child calls POSIX::setsid() then exec()s the target.
if command -v setsid >/dev/null 2>&1; then
  detach_exec() { setsid -f "$@" </dev/null >/dev/null 2>&1; }
else
  detach_exec() {
    perl -e '
      use POSIX qw(setsid);
      my $pid = fork();
      die "fork failed: $!" unless defined $pid;
      exit 0 if $pid;                       # parent: return to caller at once
      setsid();
      exec { $ARGV[0] } @ARGV or exit 1;    # child: detach and exec
    ' "$@" </dev/null >/dev/null 2>&1
  }
fi

# --- flock ------------------------------------------------------------------------
# Orchestrator decision 2. CLI subset actually used by the reference scripts:
#   flock FD           block until acquired
#   flock -n FD         try once, fail fast if held
#   flock -w SECS FD    block up to SECS seconds
# Always locks the INHERITED fd (opened by the caller via `exec N>file`).
# flock(2) locks belong to the open file description, not the process, so
# locking fd N in a short-lived child (real flock(1), or this perl fallback)
# leaves the lock held by the calling shell after that child exits -- the
# same trick util-linux's flock(1) relies on for the no-command form.
if command -v flock >/dev/null 2>&1; then
  portable_flock() { command flock "$@"; }
else
  portable_flock() {
    local nb=0 wait=0 fd=""
    while [ $# -gt 0 ]; do
      case "$1" in
        -n) nb=1; shift ;;
        -w) wait="$2"; shift 2 ;;
        *) fd="$1"; shift ;;
      esac
    done
    perl -e '
      use Fcntl qw(:flock);
      my ($nb, $wait, $fd) = @ARGV;
      open(my $fh, ">&=" . $fd) or exit 1;
      if ($wait > 0) {
        my $deadline = time() + $wait;
        while (1) {
          exit 0 if flock($fh, LOCK_EX | LOCK_NB);
          exit 1 if time() >= $deadline;
          select(undef, undef, undef, 0.1);
        }
      } elsif ($nb) {
        exit(flock($fh, LOCK_EX | LOCK_NB) ? 0 : 1);
      } else {
        exit(flock($fh, LOCK_EX) ? 0 : 1);
      }
    ' "$nb" "$wait" "$fd"
  }
fi
