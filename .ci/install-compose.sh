#!/usr/bin/env bash
# Standalone docker-compose binary: `config` validates the file without a Docker daemon.
# Prints nothing but the path of the binary on stdout.
set -euo pipefail
v=v2.29.7
case "$(uname -m)" in aarch64|arm64) arch=aarch64 ;; *) arch=x86_64 ;; esac
dir="${RUNNER_TEMP:-/tmp}/compose-$v"
if [ ! -x "$dir/docker-compose" ]; then
  mkdir -p "$dir"
  curl -fsSL -o "$dir/docker-compose" "https://github.com/docker/compose/releases/download/$v/docker-compose-linux-$arch"
  chmod +x "$dir/docker-compose"
fi
echo "$dir/docker-compose"
