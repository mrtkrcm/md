# mdviewer

Native macOS markdown viewer built with SwiftUI, `MarkdownUI`, and `Splash`.

## Requirements

- macOS 13+
- Swift 5.9+ (`swift --version`)
- Full Xcode install is recommended for running tests in all environments

## Quick Start

```bash
git clone git@github.com:mrtkrcm/mdviewer.git
cd mdviewer
bash scripts/build.sh
```

Build output binary:

```text
mdviewer/.build/arm64-apple-macosx/release/mdviewer
```

## Build and Test

```bash
cd mdviewer
swift build -c release
swift test
```

If your machine only has Command Line Tools (no full Xcode), tests may be unavailable.
You can still run release builds.

`scripts/build.sh` behavior:

- `RUN_TESTS=auto` (default): run tests only when Xcode is available
- `RUN_TESTS=true`: always run tests
- `RUN_TESTS=false`: skip tests

## Production Notes

- Dependencies are pinned in `mdviewer/Package.resolved`.
- `Info.plist` is excluded from SwiftPM compilation to keep builds warning-free.
- File save/load handles common markdown text encodings and reports write/read errors clearly.
