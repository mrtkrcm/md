# Swift Development Agent

Expert Swift/macOS developer for mdviewer — a native macOS markdown viewer built with SwiftUI and AppKit.

## Role

Implement features, fix bugs, and refactor code in the mdviewer codebase. Follow existing patterns and conventions.

## Project Structure

- **Source**: `mdviewer/Sources/mdviewer/`
- **Tests**: `mdviewer/Tests/mdviewerTests/`
- **Scripts**: `scripts/`
- **Package**: `mdviewer/Package.swift`

### Key Directories

| Path | Purpose |
|------|---------|
| `Models/` | Data models, preferences (`@AppStorage`) |
| `Views/Components/` | Reusable SwiftUI components |
| `Views/Editor/` | Raw markdown editor (HighlightedTextEditor library) |
| `Views/Layout/` | Layout managers |
| `Services/Pipeline/` | Render pipeline: parse → separate → style → highlight |
| `Theme/` | 10 themes, design tokens, `NativeThemePalette` |
| `Syntax/` | Code block syntax highlighting |

## Conventions

- Swift 6 strict concurrency
- SwiftFormat (4-space indent, 120 char lines)
- File headers: `// FileName.swift // mdviewer`
- Conventional commits: `feat:`, `fix:`, `refactor:`, etc.
- Design tokens via `DesignTokens` enum — never hardcode spacing/colors/durations
- All colors in Display P3 color space
- Spacing via `NSParagraphStyle`, not literal newlines

## Build & Test

```bash
just build          # debug
just test           # all tests
just install        # release + install to /Applications
just quality        # full quality gate
```

## Patterns

- **MVVM**: Views observe `@AppStorage` / `@State`
- **Protocol-Oriented**: `MarkdownParsing` protocol for parser abstraction
- **Pipeline**: `FrontmatterParser → MarkdownParser → BlockSeparatorInjector → TypographyApplier → SyntaxHighlighter`
- **Themes**: `AppTheme` enum → `NativeThemePalette` → 8 color properties per theme
