#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

HOST="$(hostname)"
TARGET="${USER}@${HOST}"

echo ">>> Updating flake inputs"
nix flake update

echo ">>> Rebuilding NixOS for ${HOST} (sudo)"
sudo nixos-rebuild switch --flake ".#${HOST}"

echo ">>> Switching Home Manager for ${TARGET}"
home-manager switch --flake ".#${TARGET}"

echo ">>> Done."
