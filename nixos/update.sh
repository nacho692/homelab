#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

HOST="$(hostname)"
TARGET="${USER}@${HOST}"

echo ">>> Updating flake inputs"
nix flake update

if [ -e /etc/NIXOS ]; then
  echo ">>> Rebuilding NixOS for ${HOST} (sudo)"
  sudo nixos-rebuild switch --flake ".#${HOST}"
else
  echo ">>> Skipping nixos-rebuild (not a NixOS host)"
fi

echo ">>> Switching Home Manager for ${TARGET}"
home-manager switch --flake ".#${TARGET}"

echo ">>> Done."
