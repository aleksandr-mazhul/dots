# Yabai + Skhd Quick Start Guide

## Files Location

All configs are in:
- `~/.config/yabai/` (symlinked from `~/dotfiles/macos/.config/yabai/`)
- `~/.config/skhd/` (symlinked from `~/dotfiles/macos/.config/skhd/`)

## Quick Commands

### Query Current State
```bash
~/.config/yabai/scripts/query.sh spaces     # List all workspaces
~/.config/yabai/scripts/query.sh windows    # List all windows
~/.config/yabai/scripts/query.sh sticky     # Check for sticky windows
~/.config/yabai/scripts/query.sh focused    # Show focused window
```

### Reload Configuration
```bash
# Via keyboard: shift + cmd + r
# Or manually:
bash ~/.config/yabai/scripts/reload.sh
```

### View Logs
```bash
tail -f /tmp/yabai.$(whoami).log
```

## Keybindings Cheat Sheet

### Window Navigation
- `alt+h/j/k/l` - Focus window (west/south/north/east)
- `alt+shift+h/j/k/l` - Move window (warp)
- `alt+-/=` - Resize window

### Display Management
- `cmd+alt+h/j/k/l` - Focus display
- `cmd+alt+shift+h/j/k/l` - Move window to display

### Workspace Navigation
- `alt+1` - Focus workspace 1
- `alt+b,c,d,e,m,p,q,t,u,v,w,x,z,n,y` - Focus workspace
- `alt+shift+[letter]` - Move window to workspace
- `alt+tab` - Recent workspace
- `alt+shift+f` - Toggle fullscreen

### Service Mode (Modal)
- `alt+shift+;` - Enter service mode
- Inside service mode:
  - `r` - Rebalance
  - `f` - Toggle float
  - `backspace` - Close window
  - `h/j/k/l` - Stack operations
  - `esc/q/return` - Exit service mode

## Workspace Mapping

| Letter | Index | Purpose |
|--------|-------|---------|
| _1 | 1 | General |
| B | 2 | Yandex |
| C | 3 | CLion |
| D | 4 | Discord |
| E | 5 | Finder |
| M | 6 | Mail |
| P | 7 | Preview |
| Q | 8 | Wolfram |
| T | 9 | Telegram |
| U | 10 | Spotify |
| V | 11 | Browser |
| W | 12 | WebStorm |
| X | 13 | ChatGPT |
| Z | 14 | Kitty |
| N | 15 | Notes |
| Y | 16 | Zoom |

## Configuration Files

### Main Files
- `yabairc` - Bootstrap config, sources scripts
- `skhdrc` - Keybindings (main + service modes)

### Scripts
- `spaces.sh` - Workspace management
- `rules.sh` - App-to-workspace mappings
- `signals.sh` - Event handlers
- `opacity.sh` - Window transparency (optional)
- `borders.sh` - Border styling (optional)
- `reload.sh` - Safe restart script
- `query.sh` - Debug CLI

## Customization

### Add App Rule
Edit `~/.config/yabai/scripts/rules.sh`:
```bash
["YourApp"]="X"  # Send YourApp to workspace X
```

### Adjust Padding
Edit `~/.config/yabai/yabairc`:
```bash
window_gap 8        # Space between windows
top_padding 8       # Top margin
bottom_padding 8    # Bottom margin
left_padding 8      # Left margin
right_padding 8     # Right margin
```

### Enable Borders (optional)
Edit `~/.config/yabai/scripts/borders.sh`:
```bash
BORDERS_ENABLED=true
```

### Enable Opacity (optional)
Edit `~/.config/yabai/scripts/opacity.sh`:
```bash
OPACITY_ENABLED=true
```

## Troubleshooting

### Yabai not responding
- Check if running: `pgrep yabai`
- Check logs: `tail -f /tmp/yabai.$(whoami).log`
- Reload: `shift+cmd+r` or `bash ~/.config/yabai/scripts/reload.sh`

### Skhd not responding
- Check if running: `pgrep skhd`
- Reload: `shift+cmd+r`

### Sticky windows appearing
- Check: `~/.config/yabai/scripts/query.sh sticky`
- Should return empty list

### Windows not in right workspace
- Check rules: `yabai -m rule --list`
- Edit `~/.config/yabai/scripts/rules.sh`
- Reload: `shift+cmd+r`

## Important Notes

1. **Displays with separate spaces**: Enable in System Settings > Dock & Menu Bar > Spaces
2. **Windscribe**: Configured to NOT appear on all spaces
3. **Service mode**: Exits automatically after action
4. **Labels**: Yabai requires letter labels (_1 instead of 1)
5. **Indices**: Can use both indices (1-16) and labels (_1,B,C...) to focus workspaces

## Helpful Resources

- Yabai docs: https://github.com/koekeishiya/yabai/wiki
- Skhd docs: https://github.com/koekeishiya/skhd
- Dotfiles repo: ~/dotfiles/macos/.config/

---

**Last updated**: 2026-04-29
**Configuration version**: 1.0
