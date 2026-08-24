# 🔧 Dotfiles

Чистый, модульный и полностью управляемый через **GNU Stow** репозиторий конфигурации окружения для **macOS** (с заделом под Linux).

Подход: **single source of truth** — все реальные конфиги лежат в git, а в `$HOME` создаются symlink через Stow.

---

## ✨ Что внутри

### Core CLI
- **Zsh** — модульная shell-конфигурация
- **Starship** — prompt
- **Git** — global config + ignores
- **tmux** — terminal multiplexer
- **Yazi** — TUI file manager
- **Lazygit** — Git UI
- **GitHub CLI** — `gh`
- **Homebrew** — package management

### Editor / Terminal
- **Neovim** — Lua + Lazy.nvim + LSP stack
- **Kitty** — shared terminal (macOS + Linux)
- **WezTerm** — previous terminal config (kept as fallback)
- **Ghostty** — optional terminal config

### macOS WM stack
- **yabai** — tiling window manager
- **skhd** — hotkey daemon
- **Sketchybar** — status bar
- **Borders** — focused window borders
- **Karabiner / Kanata** — keyboard remapping

### Optional
- **Hammerspoon** — utility automation
- **AeroSpace config** — legacy / experimental

---

# 📦 Repository structure

```text
dotfiles/
├── common/                        # Cross-platform configs
│   ├── .config/
│   │   ├── gh/
│   │   ├── github-copilot/
│   │   ├── kanata/
│   │   │   └── kanata.kbd         # shared HRM + layers (macOS/Linux)
│   │   ├── lazygit/
│   │   ├── nvim/
│   │   ├── starship.toml
│   │   ├── kitty/
│   │   ├── wezterm/
│   │   ├── yazi/
│   │   └── ghostty/              # optional
│   │
│   ├── .zsh/
│   │   ├── aliases.zsh
│   │   ├── base.zsh
│   │   ├── completion.zsh
│   │   ├── exports.zsh
│   │   ├── functions.zsh
│   │   └── plugins.zsh
│   │
│   ├── .editorconfig
│   ├── .gitconfig
│   ├── .gitignore_global
│   ├── .tmux.conf
│   ├── .wezterm.lua
│   ├── .zshrc
│   └── Brewfile
│
├── macos/                         # macOS-only layer
│   ├── .config/
│   │   ├── borders/
│   │   ├── kanata/
│   │   ├── karabiner/
│   │   ├── sketchybar/
│   │   ├── skhd/
│   │   ├── tmux/
│   │   ├── kitty/
│   │   ├── wezterm/
│   │   └── yabai/
│   │
│   ├── .hammerspoon/             # optional
│   │   └── init.lua
│   │
│   ├── .zsh/
│   │   └── macos.zsh
│   │
│   ├── Library/
│   │   └── LaunchAgents/
│   │       ├── com.asmvik.yabai.plist
│   │       └── com.koekeishiya.skhd.plist
│   │
│   ├── .aerospace.toml           # legacy / experimental
│   ├── .macos
│   └── .zprofile
│
├── hosts/                         # Machine-specific overrides
│   └── macbook/
│       ├── .config/
│       ├── .gitconfig.local
│       └── .zsh/
│           └── host.zsh
│
├── linux/                         # Linux layer
│   ├── .config/
│   │   ├── systemd/user/kanata.service
│   │   ├── tmux/
│   │   ├── kitty/
│   │   └── wezterm/
│   └── .zsh/
│
├── private/                       # ignored by git
│   ├── .config/
│   └── .zsh.private
│
├── scripts/
│   ├── bootstrap-macos.sh
│   ├── bootstrap-linux.sh
│   ├── install-stow.sh
│   └── sync.sh
│
├── .gitignore
├── LICENSE
└── README.md
```

---

# 🔗 GNU Stow architecture

Репозиторий управляется через **GNU Stow**.

Это значит:

- в git лежат **реальные файлы**
- в `$HOME` лежат **symlink**
- никаких копий конфигов
- никаких ручных `ln -s`

Пример:

```text
~/.zshrc
  → ~/dotfiles/common/.zshrc

~/.config/yabai
  → ~/dotfiles/macos/.config/yabai

~/Library/LaunchAgents/com.asmvik.yabai.plist
  → ~/dotfiles/macos/Library/LaunchAgents/com.asmvik.yabai.plist
```

---

# 🚀 Quick start

## Clone repo

```bash
cd ~
git clone <your-repo-url> dotfiles
cd dotfiles
```

## Install GNU Stow

macOS:

```bash
brew install stow
```

Linux:

```bash
sudo apt install stow
```

---

## Apply config

```bash
cd ~/dotfiles

stow common
stow macos
stow -d hosts -t ~ <hostname>
```

После этого конфиги подключены.

---

# 🖥 Window manager stack

Основной WM stack:

```text
yabai
+ skhd
+ sketchybar
+ borders
```

---

## Start services

### yabai

```bash
launchctl bootstrap gui/$(id -u) \
  ~/Library/LaunchAgents/com.asmvik.yabai.plist
```

reload:

```bash
launchctl kickstart -k gui/$(id -u)/com.asmvik.yabai
```

---

### skhd

```bash
launchctl bootstrap gui/$(id -u) \
  ~/Library/LaunchAgents/com.koekeishiya.skhd.plist
```

reload:

```bash
launchctl kickstart -k gui/$(id -u)/com.koekeishiya.skhd
```

---

### Sketchybar

```bash
brew services start sketchybar
```

reload:

```bash
brew services restart sketchybar
```

---

## Permissions

macOS → Privacy & Security:

Enable:

- Accessibility
- Automation
- Screen Recording (if needed)

for:

- yabai
- skhd
- Sketchybar
- Hammerspoon (optional)

---

# ➕ Add new config

Example:

```bash
mkdir -p common/.config/foo
cp -R ~/.config/foo/* common/.config/foo/
```

Apply:

```bash
stow -R common
```

Done.

---

# 🔄 Update workflow

Edit:

```bash
vim ~/.config/yabai/yabairc
```

Commit:

```bash
cd ~/dotfiles
git add -A
git commit -m "update yabai config"
git push
```

Sync on another machine:

```bash
cd ~/dotfiles
git pull --rebase

stow -R common
stow -R macos
stow -R -d hosts -t ~ <hostname>
```

---

# 🔐 Private files

Never commit:

- tokens
- secrets
- ssh keys
- credentials

Use:

```text
private/
```

Examples:

```text
private/.zsh.private
private/.config/gh/
private/.config/github-copilot/
```

---

# 🧪 Dry run check

Проверка, что структура чистая:

```bash
stow -n -v common
stow -n -v macos
stow -n -v -d hosts -t ~ <hostname>
```

Если нет conflict/error → всё корректно.

---

# 📝 Notes

- **yabai + skhd** — основной WM
- **Hammerspoon** — optional helper
- **AeroSpace config** — legacy / experimental
- **GNU Stow** — единственный source of truth

---
