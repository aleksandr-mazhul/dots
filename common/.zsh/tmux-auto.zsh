# Auto-attach tmux in Kitty only. Skip Cursor/IDE, SSH, already-in-tmux.
# NO_TMUX=1 opts out (kitty: Ctrl+Alt+N opens a plain window with it set).
# boot.sh creates the server AND restores the last resurrect snapshot (under
# flock) so `exec tmux attach` never fails and sessions survive reboots.

[[ -o interactive ]] || return
[[ -z "$TMUX" ]] || return
[[ -z "$NO_TMUX" ]] || return
[[ -n "$KITTY_WINDOW_ID" ]] || return

# Not over SSH.
[[ -z "$SSH_CONNECTION" && -z "$SSH_CLIENT" && -z "$SSH_TTY" ]] || return

# Not an IDE terminal (an IDE launched from a kitty shell inherits
# KITTY_WINDOW_ID, so this needs its own guard).
[[ "$TERM_PROGRAM" != vscode ]] || return
[[ -z "$CURSOR_TRACE_ID" ]] || return
[[ "$TERMINAL_EMULATOR" != JetBrains-JediTerm ]] || return
[[ -z "$INSIDE_EMACS" ]] || return
[[ -z ${parameters[(I)VSCODE_*]} ]] || return  # any VSCODE_* var, no fork

# tmux available: non-login shells may lack the brew PATH.
if command -v tmux >/dev/null 2>&1; then
  _tmuxauto_bin=tmux
elif [[ -x /opt/homebrew/bin/tmux ]]; then
  _tmuxauto_bin=/opt/homebrew/bin/tmux
else
  return
fi

# boot.sh creates the server and restores the last resurrect snapshot.
[[ -x "$HOME/.config/tmux/boot.sh" ]] && "$HOME/.config/tmux/boot.sh"

# One-shot target session left by boot.sh. (The fish version reads
# $XDG_RUNTIME_DIR with no fallback -- that's a bug on macOS, where it's
# unset; use the same fallback as everywhere else in this setup.)
_tmuxauto_target_file="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/tmux-boot-target"
_tmuxauto_target=""
if [[ -r "$_tmuxauto_target_file" ]]; then
  _tmuxauto_target=$(<"$_tmuxauto_target_file")
  rm -f "$_tmuxauto_target_file"  # one-shot: only the boot attach
fi

if [[ -n "$_tmuxauto_target" ]] && "$_tmuxauto_bin" has-session -t "=$_tmuxauto_target" 2>/dev/null; then
  exec "$_tmuxauto_bin" attach -t "=$_tmuxauto_target"
elif "$_tmuxauto_bin" has-session 2>/dev/null; then
  exec "$_tmuxauto_bin" attach
else
  exec "$_tmuxauto_bin" new-session
fi
