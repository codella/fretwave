#!/usr/bin/env bash
set -euo pipefail
package_dir=$(realpath "${1:?Package directory required}")
version=${2:?Version required}
: "${AUR_SSH_PRIVATE_KEY:?Configure the AUR publishing key first}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
umask 077
printf '%s\n' "$AUR_SSH_PRIVATE_KEY" > "$tmp/key"
unset AUR_SSH_PRIVATE_KEY
ssh-keyscan -t ed25519 aur.archlinux.org > "$tmp/known_hosts" 2>/dev/null
fingerprint=$(ssh-keygen -lf "$tmp/known_hosts" | awk '{print $2}')
[[ $fingerprint == 'SHA256:RFzBCUItH9LZS0cKB5UE6ceAYhBD5C8GeOBip8Z11+4' ]] || { echo 'Unexpected AUR host key' >&2; exit 1; }
export GIT_SSH_COMMAND="ssh -i $tmp/key -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=$tmp/known_hosts"
# Retry concurrent updates, and never overwrite a newer release with an older run.
for attempt in 1 2 3; do
  checkout="$tmp/aur-$attempt"
  git -c init.defaultBranch=master clone ssh://aur@aur.archlinux.org/fretwave.git "$checkout"
  if [[ -f $checkout/.SRCINFO ]]; then
    current=$(awk '$1 == "pkgver" {print $3; exit}' "$checkout/.SRCINFO")
    if [[ -n $current ]] && (( $(vercmp "$current" "$version") >= 0 )); then
      echo "AUR already has $current; nothing to publish."
      exit 0
    fi
  fi
  cp "$package_dir/PKGBUILD" "$package_dir/.SRCINFO" "$checkout/"
  git -C "$checkout" config user.name 'Mauro Codella'
  git -C "$checkout" config user.email 'mauro.codella@pm.me'
  git -C "$checkout" add PKGBUILD .SRCINFO
  git -C "$checkout" commit -m "Update Fretwave to $version"
  if git -C "$checkout" push origin HEAD:master; then exit 0; fi
done
echo 'AUR push failed after three attempts' >&2
exit 1
