# Automation Agent Guide

## Purpose
This repository is the single source of truth for dotfiles managed through GNU Stow. Agents must keep real config files in this repo and only expose them in `$HOME` via symlinks.

## Layering rules
Apply changes in the most generic layer that satisfies the need:

1. `common/` — cross-platform defaults.
2. `macos/` or `linux/` — OS-specific overrides.
3. `hosts/<hostname>/` — machine-specific overrides.
4. `private/` — local secrets/sensitive files (never commit).
5. `scripts/` — repeatable automation/bootstrap/sync helpers.

Never duplicate the same config in multiple layers without clear override intent.

## Placement decision table
| Change type | Location |
|---|---|
| Works on both macOS and Linux | `common/` |
| Works only on macOS | `macos/` |
| Works only on Linux | `linux/` |
| Only for one machine | `hosts/<hostname>/` |
| Contains tokens, credentials, private identity data | `private/` |
| Setup/apply/sync automation | `scripts/` |

## Symlink / Stow workflow
- Edit files in the repository, not in `$HOME` symlinks.
- Use Stow as the only link manager; do not create manual `ln -s` links.
- Fresh machine: `./scripts/bootstrap-macos.sh` or `./scripts/bootstrap-linux.sh` from a clone at `~/dotfiles`.
- Existing machine: `./scripts/sync.sh`.
- Stow is still the only link manager. On macOS, if `hosts/$(hostname -s)` does not exist, bootstrap and sync apply `hosts/macbook`.
- Manual equivalent:
  - `stow common`
  - `stow macos` (or `stow linux`)
  - `stow -d hosts -t ~ macbook`
- Before applying widely, run dry-run checks:
  - `stow -n -v common`
  - `stow -n -v macos` or `stow -n -v linux`
  - `stow -n -v -d hosts -t ~ <hostname>`

## Cleanup safety rules
- Quarantine first: move removed/uncertain files to a clearly named backup folder in the repo (for example `private/.quarantine/`), then verify before final deletion.
- Never run destructive deletion (`rm`, `git clean`, history rewrite, force reset) unless explicitly approved.
- Prefer reversible operations and document what was moved and why.

## Git workflow
- Start from an updated default branch: `git pull --rebase`.
- Use a dedicated branch per task.
- Keep commits focused and descriptive; avoid mixing unrelated changes.
- Verify changes before push (at minimum: Stow dry-run for impacted layers and quick sanity checks).
- Push only after verification passes.

## Pre-finish checklist
- [ ] Files placed in the correct layer (`common/macos/linux/hosts/private/scripts`).
- [ ] No secrets added outside `private/`.
- [ ] No manual symlink hacks; Stow workflow preserved.
- [ ] Dry-run Stow checks executed for impacted layers.
- [ ] Cleanup actions are reversible or explicitly approved if destructive.
- [ ] Git diff is focused, commit message is clear, and branch is ready to push.
