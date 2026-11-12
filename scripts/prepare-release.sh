#!/usr/bin/env bash
set -euo pipefail
version=${1:?Usage: prepare-release.sh VERSION OUTPUT_DIRECTORY}
out=${2:?Missing output directory}
[[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid release version' >&2; exit 1; }
mkdir -p "$out"
git archive --format=tar --prefix="fretwave-$version/" HEAD | gzip -n > "$out/fretwave-$version.tar.gz"
checksum=$(sha256sum "$out/fretwave-$version.tar.gz" | cut -d' ' -f1)
sed -e "s/@VERSION@/$version/g" -e "s/@SHA256@/$checksum/g" \
  packaging/aur/PKGBUILD.in > "$out/PKGBUILD"
(cd "$out" && makepkg --printsrcinfo > .SRCINFO)
