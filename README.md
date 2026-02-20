# mdviewer

Native macOS markdown viewer built with SwiftUI and native AppKit-backed markdown rendering.

## Requirements

- macOS 14+
- Swift 5.9+ (`swift --version`)
- Full Xcode install is recommended for running tests in all environments

## Quick Start

```bash
git clone git@github.com:mrtkrcm/mdviewer.git
cd mdviewer
bash scripts/build.sh
```

Build and replace your installed app in one command:

```bash
bash scripts/install.sh
```

Release app output:

```text
release/md.app
```

Release binary (inside app bundle):

```text
release/md.app/Contents/MacOS/md
```

Open a file from terminal:

```bash
release/md.app/Contents/MacOS/md README.md
```

## Build and Test

```bash
cd mdviewer
swift build -c release
swift test
```

## Code Quality and Formatting

Run formatting checks:

```bash
bash scripts/format.sh --check
```

Apply formatting:

```bash
bash scripts/format.sh --fix
```

Run the full quality gate (format check, release build, tests):

```bash
bash scripts/quality.sh
```

If your machine only has Command Line Tools (no full Xcode), tests may be unavailable.
You can still run release builds.

`scripts/build.sh` behavior:

- Always performs a release build and packages `release/md.app`.
- `RUN_TESTS=auto` (default): run tests only when Xcode is available
- `RUN_TESTS=true`: always run tests
- `RUN_TESTS=false`: skip tests
- `INSTALL_APP=true`: replace installed app bundle after build
- `INSTALL_DIR=/Applications` (default): target install directory
- `QUIT_RUNNING_APP=true` (default): quits/kills running installed app before replace
- `OPEN_APP_AFTER_INSTALL=false` (default): relaunch app after install

Examples:

```bash
# Build and install to /Applications
bash scripts/install.sh

# Build and install to ~/Applications (no sudo needed)
INSTALL_DIR="$HOME/Applications" bash scripts/install.sh
```

## Production Notes

- Dependencies are pinned in `mdviewer/Package.resolved`.
- `Info.plist` is excluded from SwiftPM compilation to keep builds warning-free.
- File save/load handles common markdown text encodings and reports write/read errors clearly.
- Markdown document support includes `.md`, `.markdown`, `.mdown`, and `.mkd` on open.
- New documents start empty and save as markdown by default.
- A minimal welcome screen appears on startup only when no document content is loaded.
- Starter content can be inserted/reset from the document toolbar menu.
- Settings include markdown theme, Swift syntax palette, reader text size, and code font size.
