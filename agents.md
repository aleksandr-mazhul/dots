# Agents Map: Token-Efficient Navigation for `dotfiles`

This file is a **high-signal map for coding agents** working in this repository.  
Goal: **find the right files fast**, avoid wasting tokens, and keep edits safe.

---

## 1) Repository purpose (what this repo is)

- This is a **GNU Stow-managed dotfiles repo**.
- Real config files live in git; `$HOME` should mostly contain symlinks into this repo.
- Main layers:
  - `common/` — shared for all systems
  - `macos/` — macOS-only
  - `linux/` — Linux-only
  - `hosts/` — host-specific overrides
  - `private/` — sensitive local-only files (never commit secrets)
  - `scripts/` — bootstrap/sync automation

If you only remember one thing: **edit files in repo layers, not in `$HOME` symlink targets**.

---

## 2) Fast path: where to look first by task

| Task | Read first | Then read |
|---|---|---|
| Shell behavior, aliases, PATH | `common/.zshrc`, `common/.zsh/*.zsh` | `macos/.zsh/macos.zsh` or `linux/.zsh/linux.zsh`, then `hosts/*/.zsh/host.zsh` |
| Git behavior | `common/.gitconfig` | `hosts/*/.gitconfig.local` |
| Terminal prompt | `common/.p10k.zsh`, `common/.config/starship.toml` | OS-specific terminal config |
| Neovim config | `common/.config/nvim/init.lua` | `common/.config/nvim/lua/**` (if present) |
| WezTerm | `common/.wezterm.lua`, `common/.config/wezterm/wezterm.lua` | `macos/.config/wezterm/macos.lua` or `linux/.config/wezterm/linux.lua` |
| Kitty | `common/.config/kitty/kitty.conf` | `macos/.config/kitty/macos.conf` or `linux/.config/kitty/linux.conf` |
| tmux config | `common/.tmux.conf` | `macos/.config/tmux/macos.conf` or `linux/.config/tmux/linux.conf` |
| Keyboard remap (Karabiner/Kanata) | `common/.config/kanata/kanata.kbd` | `macos/.config/kanata/` (daemon scripts), `linux/.config/systemd/user/kanata.service` |
| Yabai/Skhd/Sketchybar | `macos/.config/yabai/yabairc`, `macos/.config/skhd/skhdrc`, `macos/.config/sketchybar/sketchybarrc` | `macos/Library/LaunchAgents/*.plist` |
| Bootstrap / apply links | `scripts/bootstrap-macos.sh`, `scripts/bootstrap-linux.sh`, `scripts/sync.sh` | `scripts/install-stow.sh`, `README.md` |
| Host-specific issue | `hosts/<hostname>/**` | base layer being overridden (`common/` or OS layer) |

---

## 3) Canonical file map (high-value files)

### Root
- `README.md` — human architecture + usage reference.
- `agent.md` — concise automation policy.
- `agents.md` (this file) — token-optimized navigation map.

### `common/` (cross-platform core)
- `common/.zshrc`
- `common/.zsh/{base,aliases,exports,functions,completion,plugins}.zsh`
- `common/.gitconfig`, `common/.gitignore_global`
- `common/.tmux.conf`
- `common/.wezterm.lua`
- `common/.config/kitty/kitty.conf`
- `common/.config/nvim/init.lua`
- `common/.config/gh/config.yml`
- `common/.config/lazygit/config.yml`
- `common/.config/yazi/*.toml`
- `common/.config/kanata/kanata.kbd`
- `common/Brewfile`

### `macos/` (macOS-only)
- `macos/.zprofile`
- `macos/.zsh/macos.zsh`
- `macos/.macos`
- `macos/.aerospace.toml`
- `macos/.config/yabai/yabairc`
- `macos/.config/kitty/macos.conf`
- `macos/.config/skhd/skhdrc`
- `macos/.config/sketchybar/sketchybarrc`
- `macos/.config/karabiner/karabiner.json`
- `macos/.config/kanata/{plist,scripts,*.kbd}`
- `macos/Library/LaunchAgents/*.plist`

### `linux/` (Linux-only)
- `linux/.zsh/linux.zsh`
- `linux/.config/tmux/linux.conf`
- `linux/.config/kitty/linux.conf`
- `linux/.config/wezterm/linux.lua`
- `linux/.config/systemd/user/kanata.service`

### `hosts/` (machine overrides)
- `hosts/macbook/.gitconfig.local`
- `hosts/macbook/.zsh/host.zsh`

### `private/` (sensitive)
- `private/.zsh.private`
- `private/.config/gh/hosts.yml`
- `private/.config/github-copilot/{apps.json,oauth.json}`

### `scripts/` (operational entry points)
- `scripts/bootstrap-macos.sh`
- `scripts/bootstrap-linux.sh`
- `scripts/sync.sh`
- `scripts/install-stow.sh`
- `scripts/update-macos.sh`

---

## 4) Files agents should usually NOT read first (token savers)

Read these **only if directly needed**:

1. `macos/.config/karabiner/karabiner.json` (~136KB)  
   - Large and verbose; use targeted search (`rg`) or `jq` extraction first.
2. `common/.p10k.zsh` (~88KB)  
   - Generated-ish style config; usually irrelevant unless prompt issue.
3. `common/.config/nvim/lazy-lock.json`  
   - Dependency lock; avoid unless plugin pin/version issue.
4. `private/**`  
   - Sensitive; avoid by default unless the task explicitly needs it.
5. Any backup/quarantine directories outside repo  
   - Not source-of-truth for config behavior.

Rule: **Prefer targeted grep/jq slices over full-file reads on large configs.**

---

## 5) Token-efficient investigation strategy

1. Start with `README.md` + `scripts/*.sh` + one relevant layer file.
2. Use `rg` on exact symbol/keyword before opening large files.
3. For JSON (especially Karabiner), use `jq` selectors by `description`, `key_code`, or variables.
4. Read smallest override chain first:
   - `common` -> OS (`macos`/`linux`) -> `hosts/<hostname>`
5. Only open `private/` after confirming task scope explicitly requires it.

---

## 6) Layer placement rules (for edits)

- Put config in the **lowest-entropy** layer:
  - Cross-platform default -> `common/`
  - OS-specific behavior -> `macos/` or `linux/`
  - Single-machine tweaks -> `hosts/<hostname>/`
  - Secrets/tokens -> `private/` (never commit secrets elsewhere)
- Avoid duplication between layers unless a deliberate override is needed.
- If moving a file across layers, update docs/scripts references in same change.

---

## 7) Stow/symlink truth model

- Commands currently expected:
  - `stow common`
  - `stow macos` or `stow linux`
  - `stow -d hosts -t ~ <hostname>`
- Host package selection lives in `scripts/lib/host-package.sh`. It uses `HOST_PACKAGE` or `hostname -s`, and on macOS falls back to `hosts/macbook` (this machine's hostname is `MBP-M1-Pro`).
- Never replace this with ad-hoc manual `ln -s` unless user explicitly asks.

---

## 8) Quick diagnostics commands agents can reuse

```bash
# repo status
git --no-pager status --short

# check host package availability
HOST_PACKAGE="${HOST_PACKAGE:-$(hostname -s)}"
test -d "hosts/$HOST_PACKAGE" && echo "host package exists" || echo "host package missing"

# dry-run stow checks
stow -n -v common
stow -n -v macos   # or linux
stow -n -v -d hosts -t "$HOME" "$HOST_PACKAGE"

# locate home symlinks pointing to dotfiles
find "$HOME" -maxdepth 3 -type l -lname "*dotfiles*" 2>/dev/null

# targeted Karabiner search
jq '.profiles[] | .complex_modifications.rules[] | select(.description=="cmd layer for arrows")' macos/.config/karabiner/karabiner.json
```

---

## 9) Safety rails (must-follow)

- Never run destructive cleanup beyond agreed scope.
- Cleanup policy: quarantine-first, delete later only if explicitly approved.
- Do not commit secrets or machine-specific sensitive data outside `private/`.
- Keep commits scoped; avoid bundling unrelated changes.

---

## 10) Minimal read checklist before coding

1. `README.md` (current architecture)
2. Relevant file from `common/`
3. Matching OS layer file (`macos/` or `linux/`)
4. Matching host override (`hosts/<hostname>/`) if exists
5. Relevant script in `scripts/` if behavior depends on setup/sync

If this checklist is followed, agents usually avoid 80%+ unnecessary token spend.

