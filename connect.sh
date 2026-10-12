#!/usr/bin/env bash
# Usage: ./connect.sh windows|macos|linux [run-id]
# Decrypts the run's tunnel hostname and opens a local port to it.
set -euo pipefail
os=$1
run=${2:-$(gh run list -R ancs21/spacetoy -w remote-machines.yml -L 1 --json databaseId --jq '.[0].databaseId')}
dir=$(mktemp -d)
gh run download "$run" -R ancs21/spacetoy -n "host-$os" -D "$dir"
host=$(openssl enc -d -aes-256-cbc -pbkdf2 -a -A -pass pass:"$(security find-generic-password -s spacetoy-remote -w)" < "$dir/host-$os.enc")
case $os in
  windows) echo "RDP to localhost:13389  user: runneradmin"; exec cloudflared access rdp --hostname "$host" --url localhost:13389 ;;
  macos)   echo "Open vnc://localhost:15900  user: remote"; exec cloudflared access tcp --hostname "$host" --url localhost:15900 ;;
  linux)   exec ssh -o ProxyCommand="cloudflared access ssh --hostname %h" -o StrictHostKeyChecking=no "runner@$host" ;;
esac
