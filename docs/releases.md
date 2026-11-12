# Automatic GitHub releases

Every push to `main` builds and tests Fretwave in an Arch Linux container, then
publishes a GitHub release. Branch pushes do not publish. You can also run the
workflow manually. Versions are `0.1.<workflow run number>`; failed builds can
leave gaps. Rerunning a workflow uses the same version.

Each release includes the source archive, an x86_64 Arch package, a debug package,
and its `PKGBUILD`. The recipe downloads the exact release archive and verifies
its SHA-256 checksum. All three tests run during package creation.

Publication uses GitHub's built-in, short-lived workflow token. No external
publishing accounts or SSH keys are required.

## Local package verification

On Arch Linux, with the dependencies listed in `packaging/arch/PKGBUILD.in` installed:

```sh
bash scripts/prepare-release.sh 0.1.1 /tmp/fretwave-package-check
cd /tmp/fretwave-package-check
makepkg --noconfirm
```

The source archive uses committed files (`HEAD`), so commit changes before testing.
Use a build path without spaces because makepkg's default debug flags embed it.
To intentionally change the version series, update the workflow's version prefix
and CMake's default version together. Keep versions increasing.
