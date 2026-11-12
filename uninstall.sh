#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
build_dir="$project_dir/build"
prefix="$HOME/.local"
dry_run=false
usage() {
  cat <<'HELP'
Usage: ./uninstall.sh [--build-dir DIR] [--prefix DIR] [--dry-run]

Remove a source installation using DIR/install_manifest.txt.
Defaults: build directory beside this script; installation prefix ~/.local.
Use your package manager instead for installations from an Arch package.
HELP
}
while (($#)); do
  case "$1" in
    --build-dir|--prefix)
      (($# >= 2)) || { usage >&2; exit 2; }
      case "$1" in
        --build-dir) build_dir=$2 ;;
        --prefix) prefix=$2 ;;
      esac
      shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
manifest="$build_dir/install_manifest.txt"
[[ -s $manifest ]] || { echo "No installation record found: $manifest" >&2; exit 1; }
prefix=$(realpath -m -- "$prefix")
[[ $prefix != / ]] || { echo 'Refusing to use / as the installation prefix.' >&2; exit 1; }

# Validate every entry before removing anything. Never recursively remove directories.
files=()
while IFS= read -r file || [[ -n $file ]]; do
  [[ -n $file ]] || continue
  [[ $file == /* && $file == "$prefix/"* ]] || {
    echo "Installation record does not match prefix $prefix: $file" >&2; exit 1;
  }
  relative=${file#"$prefix/"}
  case "$relative" in
    bin/fretwave|share/applications/io.github.codella.fretwave.desktop|\
    share/icons/hicolor/scalable/apps/io.github.codella.fretwave.svg|\
    share/icons/hicolor/16x16/apps/io.github.codella.fretwave.png|\
    share/icons/hicolor/32x32/apps/io.github.codella.fretwave.png|\
    share/icons/hicolor/48x48/apps/io.github.codella.fretwave.png|\
    share/icons/hicolor/64x64/apps/io.github.codella.fretwave.png|\
    share/icons/hicolor/128x128/apps/io.github.codella.fretwave.png|\
    share/icons/hicolor/256x256/apps/io.github.codella.fretwave.png|\
    share/doc/fretwave/LICENSE|share/doc/fretwave/THIRD_PARTY_NOTICES.md|\
    share/doc/fretwave/fonts/OFL.txt|share/doc/fretwave/fonts/Oswald-OFL.txt|\
    share/doc/fretwave/fonts/Lato-OFL.txt) ;;
    *) echo "Refusing unexpected installation entry: $file" >&2; exit 1 ;;
  esac
  parent=$(realpath -m -- "$(dirname -- "$file")")
  [[ $parent == "$prefix/"* ]] || {
    echo "Refusing path redirected outside the installation prefix: $file" >&2; exit 1;
  }
  [[ ! -d $file || -L $file ]] || { echo "Expected a file, found a directory: $file" >&2; exit 1; }
  files+=("$file")
done < "$manifest"
for file in "${files[@]}"; do
  if [[ -e $file || -L $file ]]; then
    if $dry_run; then
      printf 'Would remove: %s\n' "$file"
    else
      rm -- "$file"
      printf 'Removed: %s\n' "$file"
    fi
  fi
done
if $dry_run; then
  echo 'Preview complete; no files were removed.'
else
  echo 'Fretwave uninstalled. Missing files were skipped; shared directories were preserved.'
fi
