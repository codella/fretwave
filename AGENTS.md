# Project instructions

## Working with the user

- For a new app, assume a Rust TUI, but always confirm the format first. For this
  project, the user has already chosen a graphical Qt6 app using C++ and Qt Quick/QML
  for KDE Plasma. Do not ask again or migrate it to a TUI.
- Challenge assumptions when warranted and explain why.
- Keep communication concise and use plain language.
- Prefer restrained, polished UI changes. Preserve the established teal accent,
  typography, and guitar-pick icon unless the user requests a change.

## Fretwave

- The canonical source is at the repository root, not under `outputs/`.
- `src/` contains the C++ chord model and audio synthesis.
- `qml/` contains the chord browser, fretboard, and note wheels.
- The app is an offline chord reference with playback, not a quiz.
- Preserve correct guitar tuning, note spelling, voicings, and proportional fret
  spacing when changing the diagrams or chord data.
- Original code and artwork use GPL-3.0-only. Bundled fonts retain their OFL
  licenses and attribution; see `THIRD_PARTY_NOTICES.md`.

## Build and verification

```sh
cmake -S . -B work/release-build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build work/release-build --parallel
ctest --test-dir work/release-build --output-on-failure
./work/release-build/fretwave
```

- Dependencies and installation instructions are in `README.md` and
  `CMakeLists.txt`.
- Run the relevant checks for code changes. The test suite covers audio synthesis,
  chord integrity, and the UI workflow. Documentation-only edits do not need a rebuild.
- For a visual check, the app supports `--smoke-test --screenshot PATH`,
  `--tab N`, and `--focus`. Offscreen rendering can use
  `QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software`.
- Build outputs and temporary files belong in ignored `work/`, `build/`, or `/tmp`.

## Publishing

- The GitHub repository is `codella/fretwave`. Use `gh` for GitHub operations.
- Every successful push to `main` creates a GitHub release after building and
  testing an Arch package. A push therefore has a release side effect.
- See `.github/workflows/release.yml` and `docs/releases.md` for the release process.
- The user explicitly canceled AUR publishing. Do not add AUR automation,
  publishing credentials, or account setup unless explicitly requested again.
- Never commit private keys, tokens, or other secrets.
