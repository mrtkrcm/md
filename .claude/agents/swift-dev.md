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
| `Theme/` | 10 themes, design tokens, `NativeThemePalette`, `ThemeData` |
| `Syntax/` | Code block syntax highlighting |
| `Design/` | ViewModifiers, TransitionKit — reusable UI patterns |

## Conventions

- Swift 6 strict concurrency
- SwiftFormat (4-space indent, 120 char lines)
- File headers: `// FileName.swift // mdviewer`
- Conventional commits: `feat:`, `fix:`, `refactor:`, etc.
- Design tokens via `DesignTokens` enum — never hardcode spacing/colors/durations
  - Sub-namespaces: `CornerRadius`, `Spacing`, `Animation`, `Opacity`, `Shadow`, `Layout`, `Typography`
  - `SemanticColors` for state colors (success/warning/error/info)
  - `Component.Button/Card/Input/List/Toolbar/Modal` for component-level tokens
  - `AnimationPreset` / `TransitionPreset` / `SpacingScale` for preset values
- All colors in Display P3 color space via `NativeThemePalette.p3Color`
- Theme color data lives in `ThemeData.swift` (`ThemeRegistry` enum + `ThemeColorData` struct)
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
- **Themes**: `AppTheme` enum → `ThemeRegistry` (structured data) → `NativeThemePalette` → 20+ color properties per theme
- **ViewModifiers**: use existing modifiers in `Design/ViewModifiers.swift` (`CardStyleModifier`, `ButtonStyleModifier`, `ShimmerModifier`, `TooltipModifier`, etc.) before writing ad-hoc styling

## Quality Gate Notes

- `just lint-fix` auto-fixes are safe for most rules but **avoid running on files with `?? expr` after trailing closures** — it can corrupt `contains(where:)` into invalid syntax
- `trailing_comma` and `opening_brace` are disabled in SwiftLint (intentional conflict resolution with SwiftFormat)
- Add new single-char identifiers to `identifier_name.excluded` in `.swiftlint.yml` if needed
