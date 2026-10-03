# Dotfiles

GNU Stow configurations for a Mac that is also usable on Linux. The files in git are the real configs. `$HOME` only gets symlinks.

```bash
git clone git@github.com:Aleksandr-Mazhul/dots.git ~/dotfiles
cd ~/dotfiles
./scripts/bootstrap-macos.sh
```

On Linux, `./scripts/bootstrap-linux.sh` links the shared and Linux packages. It does not install distro packages.

Homebrew has to exist before the macOS script (https://brew.sh). Xcode Command Line Tools have to exist before Homebrew. The script installs Stow, installs [the Brewfile](common/Brewfile), then links `common`, `macos`, and the host package.

Three things on a new Mac are still manual, because the system will not grant them to a script:

1. Accessibility for yabai, skhd, and SketchyBar.
2. `sudo yabai --load-sa`
3. `macos/.config/kanata/scripts/install-daemon.sh` for the keyboard daemon.

Secrets are not in the clone. Copy `private/` yourself.

## What you get

| | |
|---|---|
| Shell | zsh, Powerlevel10k, fzf, zoxide |
| Editor | Neovim (LazyVim) |
| Terminal | Kitty day to day. WezTerm and Ghostty configs stay in the repo. |
| Multiplexer | tmux, with a launchd timer that saves the session |
| Window manager | yabai, skhd, SketchyBar, borders |
| Keyboard | Kanata, with Karabiner's VirtualHID driver |
| Tools | git, GitHub CLI, lazygit, yazi |

AeroSpace is installed by the Brewfile and configured, and it does not start at login. yabai is the window manager.

## Layout

Stow packages map onto `$HOME`. A later package fills in files the earlier one does not have. Nothing here is copied.

```text
common/     shell, git, nvim, kitty, tmux, kanata layout, Brewfile
macos/      yabai, skhd, SketchyBar, borders, Karabiner, LaunchAgents
linux/      Linux shell, kitty, tmux, kanata user service
hosts/      this MacBook: hosts/macbook
private/    gitignored secrets
scripts/    bootstrap, sync, update
```

`hosts/macbook` is the host package. This machine's short hostname is `MBP-M1-Pro`, so bootstrap and sync apply `hosts/macbook` when `hosts/$(hostname -s)` is missing. Override with `HOST_PACKAGE`.

Edit files in the repo. The path in `$HOME` is a symlink to that file.

```text
~/.zshrc          →  ~/dotfiles/common/.zshrc
~/.config/nvim    →  ~/dotfiles/common/.config/nvim
~/.config/yabai   →  ~/dotfiles/macos/.config/yabai
```

## Day to day

```bash
cd ~/dotfiles
./scripts/sync.sh
```

That pulls with rebase and re-stows. On macOS, `./scripts/update-macos.sh` also upgrades Homebrew.

Dry-run before a risky link:

```bash
stow -n -v common
stow -n -v macos
stow -n -v -d hosts -t ~ macbook
```

## Secrets

`private/` is gitignored. Keep tokens there, not next to the public GitHub CLI config.

Ignored on purpose:

- `private/.zsh.private`
- `private/.config/gh/hosts.yml`
- `private/.config/github-copilot/`
- `common/.config/gh/hosts.yml` if `gh auth login` writes it into the stowed directory

Do not `git add -A`.

## This machine

LaunchAgents expand `$HOME` through a shell, so another account can load them. One exception: `launchd` does not expand paths it watches, so screenshot filing still points at `/Users/alexandermazhul/screenshots` in `macos/Library/LaunchAgents/com.alexandermazhul.screenshot-clipboard.plist`.

The Kanata layout in `common/.config/kanata/kanata.kbd` still calls the media-key helper by the absolute path on this Mac. Re-running `install-daemon.sh` rewrites the system daemon plist for the current home. It does not rewrite that layout file.
