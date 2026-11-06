#!/usr/bin/env bash
# Install Terraform into ~/.local/bin without unzip/sudo (CI runners). The version comes from the Makefile.
set -euo pipefail
bin="$HOME/.local/bin"
if ! command -v terraform >/dev/null 2>&1 && [ ! -x "$bin/terraform" ]; then
  v=$(sed -n 's/^TERRAFORM_VERSION ?= //p' Makefile)
  case "$(uname -m)" in aarch64|arm64) arch=arm64 ;; *) arch=amd64 ;; esac
  tmp=$(mktemp -d)
  mkdir -p "$bin"
  curl -fsSL -o "$tmp/tf.zip" "https://releases.hashicorp.com/terraform/${v}/terraform_${v}_linux_${arch}.zip"
  python3 -m zipfile -e "$tmp/tf.zip" "$tmp/tf"
  install -m 0755 "$tmp/tf/terraform" "$bin/terraform"
  rm -rf "$tmp"
fi
command -v terraform >/dev/null 2>&1 || echo "$bin" >> "${GITHUB_PATH:-/dev/null}"
PATH="$bin:$PATH" terraform version
