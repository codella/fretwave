# Releases and AUR publishing

Every push to `main` builds and tests Fretwave in an Arch Linux container, then
publishes a GitHub release. Branch pushes do not publish. You can also run the
workflow manually. Versions are `0.1.<workflow run number>`; failed builds can
leave gaps. Rerunning a workflow uses the same version.

Each release includes the source archive, an x86_64 Arch package, `PKGBUILD`,
and `.SRCINFO`. AUR distributes the build recipe, not the binary package.
The recipe downloads the exact release archive and verifies its SHA-256 checksum.
All three tests run during package creation. GitHub publication requires only the
repository's built-in workflow token.

## One-time AUR setup

1. Create an account at https://aur.archlinux.org/register and verify your email.
2. Add the key in [aur-publishing-key.pub](aur-publishing-key.pub) to your AUR
   account's SSH public key setting. The matching private key is stored only as
   the repository Actions secret `AUR_SSH_PRIVATE_KEY`.
3. Set the GitHub Actions repository variable `AUR_ENABLED` to `true`:
   `gh variable set AUR_ENABLED --body true --repo codella/fretwave`.
4. Rerun the latest release workflow to publish its package recipe to AUR.

The account must own or co-maintain the `fretwave` AUR package. The initial push
creates it if the name is still available. The package name was available when
this workflow was prepared. The SSH host key is checked against AUR's published
Ed25519 fingerprint. Concurrent runs cannot downgrade the AUR package version.

If AUR rejects a push, the GitHub release remains available and the workflow
reports a failure. Fix the access issue and rerun it. Do not paste private keys
into issues, chat, or source files. To rotate the key, replace the GitHub secret
and the public key registered with AUR.

## Local package verification

On Arch Linux, with the dependencies listed in `packaging/aur/PKGBUILD.in` installed:

```sh
bash scripts/prepare-release.sh 0.1.1 "$PWD/work/package-check"
cd work/package-check
makepkg --noconfirm
```

The source archive uses committed files (`HEAD`), so commit changes before testing.
To intentionally change the version series, update the workflow's version prefix
and CMake's default version together. Keep versions increasing.
