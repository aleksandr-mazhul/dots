#!/usr/bin/env bash
# Stow hosts/<name> from the repo root.
# This Mac's short hostname is MBP-M1-Pro. The only host package is hosts/macbook.

stow_host_package() {
  local mode="${1:-stow}"
  local short pkg

  short="$(hostname -s)"
  pkg="${HOST_PACKAGE:-$short}"

  if [[ ! -d "hosts/$pkg" ]]; then
    if [[ -z "${HOST_PACKAGE:-}" && "$(uname -s)" == "Darwin" && -d "hosts/macbook" ]]; then
      echo "Hostname is ${short}. Applying hosts/macbook."
      pkg="macbook"
    else
      echo "No host package hosts/${pkg}. Skipping host overrides."
      return 0
    fi
  fi

  if [[ "$mode" == "restow" ]]; then
    stow -R -d hosts -t "$HOME" "$pkg"
  else
    stow -d hosts -t "$HOME" "$pkg"
  fi
}
