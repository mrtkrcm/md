# mdviewer

Native macOS markdown viewer built with SwiftUI and AppKit-backed rendering.

## Requirements

- macOS 14+
- Swift 5.9+
- [Just](https://github.com/casey/just) command runner (`brew install just`)

## Quick Start

```bash
git clone git@github.com:mrtkrcm/mdviewer.git
cd mdviewer
just install        # build + install to /Applications
```

## Build Commands

| Command | Purpose |
|---------|---------|
| `just build` | Fast debug build (iteration) |
| `just release` | Release build only |
| `just package` | Release build + app bundle (no install) |
| `just install` | Build + package + install to `/Applications` |
| `just install-open` | Same as install + launch app |
| `just clean` | Remove all build artifacts |

## Testing

```bash
just test               # all tests
just test-parallel      # faster parallel run
just test-coverage      # with code coverage
just test-e2e           # E2E tests (builds app first)
```

## Code Quality

```bash
just quality            # full gate: format + lint + build + test
just format-fix         # auto-fix formatting
just lint-fix           # auto-fix lint issues
```

## Development

```bash
just run                # run from source (debug)
just xcode              # open in Xcode
just install-deps       # install SwiftFormat, SwiftLint, Lefthook
just setup-hooks        # install git hooks
```

## App Output

```
release/md.app                      # packaged app bundle
release/md.app/Contents/MacOS/md    # release binary
```

Open a file from terminal:

```bash
/Applications/md.app/Contents/MacOS/md README.md
```

## Build Script Flags

`scripts/build.sh` supports fine-grained control:

| Flag | Effect |
|------|--------|
| `--no-install` | Package only, don't install |
| `--no-tests` | Skip test suite |
| `--skip-build` | Package using existing binary |
| `--quiet` | Errors only (for CI) |
| `--open` | Launch app after install |
| `--no-strip` | Keep debug symbols |

Environment overrides: `INSTALL_DIR`, `BUNDLE_ID`, `APP_VERSION`, `APP_BUILD`.

## Architecture

```
mdviewer/Sources/mdviewer/
├── Models/          # Data models, preferences
├── Views/           # SwiftUI views + AppKit components
│   ├── Components/  # Reusable UI
│   ├── Editor/      # Raw markdown editing
│   └── Layout/      # Layout managers, ruler views
├── Services/        # Business logic
│   └── Pipeline/    # Markdown render pipeline
├── Theme/           # Design tokens, 10 themes
├── Syntax/          # Code syntax highlighting
└── Design/          # Design system reference
```

## Features

- 10 themes (Basic, GitHub, DocC, Solarized, Gruvbox, Dracula, Monokai, Nord, One Dark, Tokyo Night)
- Light/dark mode for all themes
- 3 spacing presets (compact, balanced, relaxed)
- Raw markdown view with syntax highlighting
- Rendered view with native typography
- YAML frontmatter support
- Document type support: `.md`, `.markdown`, `.mdown`, `.mkd`

## Production Notes

- Dependencies pinned in `mdviewer/Package.resolved`
- Ad-hoc codesigned for local use
- Atomic installs (zero-downtime replace via staging directory)
- Version derived from git tags automatically
