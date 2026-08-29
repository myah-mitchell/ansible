#!/usr/bin/env bash
# Clone this repo's private overlay and drop its two files into place.
#
# Usage:
#   ./scripts/bootstrap-private.sh <private-repo-url> [dest]
#   PRIVATE_REPO_TOKEN=<fine-grained PAT> ./scripts/bootstrap-private.sh git@github.com:you/ansible-private.git
#
# <private-repo-url> is any URL `git clone` accepts. If PRIVATE_REPO_TOKEN is
# set and the URL is HTTPS, the token is injected as an x-access-token
# credential (a fine-grained, read-only PAT scoped to just that one repo is
# recommended — nothing in the overlay is a true secret, but there's no
# reason the clone itself needs to be any more open than it has to be).
#
# [dest] defaults to this repo's own root — i.e. run this from inside a
# checkout you're about to provision with, right before `ansible-playbook`.
#
# You can also try this against the local example skeleton with no PAT:
#   ./scripts/bootstrap-private.sh ./private-repo.example
set -euo pipefail

repo_url="${1:?usage: bootstrap-private.sh <private-repo-url> [dest]}"
dest="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

if [[ -d "$repo_url" ]]; then
  # Local path (e.g. private-repo.example/) — use directly, no clone needed.
  src="$repo_url"
else
  scratch="$(mktemp -d)"
  trap 'rm -rf "$scratch"' EXIT

  clone_url="$repo_url"
  if [[ -n "${PRIVATE_REPO_TOKEN:-}" && "$repo_url" == https://* ]]; then
    clone_url="${repo_url/https:\/\//https:\/\/x-access-token:${PRIVATE_REPO_TOKEN}@}"
  fi

  git clone --depth 1 "$clone_url" "$scratch/private"
  src="$scratch/private"
fi

if [[ ! -f "$src/hosts.yml" || ! -f "$src/group_vars/all/private.yml" ]]; then
  echo "error: $src is missing hosts.yml and/or group_vars/all/private.yml" >&2
  exit 1
fi

mkdir -p "$dest/group_vars/all"
cp "$src/hosts.yml" "$dest/hosts.yml"
cp "$src/group_vars/all/private.yml" "$dest/group_vars/all/private.yml"

echo "Copied hosts.yml and group_vars/all/private.yml from $repo_url into $dest"
echo "That checkout is now locally modified — never commit or push it back."
