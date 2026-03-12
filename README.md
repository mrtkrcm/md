# mdviewer

<!-- This repository contains mdviewer, a native macOS app for viewing and navigating Markdown documents. -->

Native macOS markdown viewer built with SwiftUI and AppKit-backed rendering.

## Requirements

- macOS 15+ (Liquid Design & ProMotion optimizations)
- Swift 6.0+
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

## Features

### Viewing
- **Interactive Table of Contents** - Navigate long documents via the sidebar outline
- **120fps Smooth Scrolling** - Optimized rendering pipeline for ProMotion displays
- 10 themes (Basic, GitHub, DocC, Solarized, Gruvbox, Dracula, Monokai, Nord, One Dark, Tokyo Night)
- Light/dark mode for all themes
- 3 spacing presets (compact, balanced, relaxed)
- Raw markdown view with syntax highlighting
- Rendered view with native typography
- YAML frontmatter support with metadata inspector
- Document type support: `.md`, `.markdown`, `.mdown`, `.mkd`

### Accessibility ✨
- **Semantic Element Hierarchy** - Headings, lists, and tables exposed natively to VoiceOver
- **Heading navigation** - Navigate documents by H1-H6 via VoiceOver rotor
- **Loading announcements** - "Loading document..." for files >50KB
- **Large file warnings** - Configurable threshold (500KB - 10MB, or disable)
- **Mode change feedback** - Announces "Switched to rendered/raw mode"
- **Reduced motion support** - All animations respect system settings
- **Keyboard navigation** - Full keyboard access to all features

### Design System
- **2026 Liquid Design Language** - Modern lensing, refraction, and corner concentricity
- **Morphing Transitions** - Fluid geometry-aware view changes
- Semantic tokens, component tokens, animation/transition presets
- Glass panel effects and liquid design language
- Fluid animations with reduced motion fallbacks

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Toggle Bold | `Cmd+B` |
| Toggle Italic | `Cmd+I` |
| Insert Code Block | `Cmd+Shift+K` |
| Insert Link | `Cmd+K` |
| Insert Image | `Cmd+Shift+I` |
| Rendered Mode | `Cmd+Option+R` |
| Raw Mode | `Cmd+Option+E` |
| Zoom In/Out | `Cmd+=` / `Cmd+-` |
| Reset Zoom | `Cmd+0` |
| Appearance Settings | `Cmd+Shift+T` |
| Settings | `Cmd+,` |
| New Tab | `Cmd+T` |
| Full Screen | `Cmd+Ctrl+F` |

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

## Production Notes

- Dependencies pinned in `mdviewer/Package.resolved`
- Ad-hoc codesigned for local use
- Atomic installs (zero-downtime replace via staging directory)
- Version derived from git tags automatically
- 491 tests with >95% code coverage
