# mdviewer — Agent Instructions

Native macOS markdown viewer built with SwiftUI and AppKit (macOS 14+, Swift 6.0).

## NON-NEGOTIABLE

- Read files before editing. Make precise, minimal edits — no reformats of untouched code.
- Run `just quality` once before committing. All checks must pass.
- Do not run `just quality` or the full test suite on every iteration. During development, run only the narrowest relevant check, and if one test fails, rerun only that test or the smallest relevant test group until it passes.
- Never hardcode spacing, colors, or durations — use `DesignTokens` enum.
- Never use `print()` or `NSLog()` — use `os_log` / `Logger`.
- All colors must use Display P3 color space via `NativeThemePalette.p3Color`.
- Conventional commits: `feat:`, `fix:`, `refactor:`, `perf:`, `test:`, `style:`, `docs:`, `chore:`.

## Project Layout

```
mdviewer/Sources/mdviewer/
├── Models/            # Data models, preferences (@AppStorage)
├── Views/
│   ├── Components/    # Reusable SwiftUI components
│   ├── Editor/        # Raw markdown editor (HighlightedTextEditor)
│   └── Layout/        # AppKit layout managers, ruler views
├── Services/
│   └── Pipeline/      # Render pipeline: parse → separate → style → highlight
├── Theme/             # AppTheme enum, DesignTokens, NativeThemePalette, ThemeData
├── Syntax/            # Code block syntax highlighting
└── Design/            # ViewModifiers, TransitionKit
```

## Commands

```bash
just build          # debug build
just test           # 287 tests
just quality        # format + lint + build + test (must pass before commit)
just format-fix     # auto-fix SwiftFormat
just lint-fix       # auto-fix SwiftLint (see warning below)
just install        # release build → /Applications/md.app
just xcode          # open in Xcode
just install-deps   # install SwiftFormat, SwiftLint, Lefthook
```

## Architecture

**Render pipeline** (composable, order-dependent):
`FrontmatterParser → MarkdownParser → BlockSeparatorInjector → TypographyApplier → SyntaxHighlighter`

**Themes** (10 total, light + dark):
`AppTheme` enum → `ThemeRegistry` (`ThemeData.swift`) → `NativeThemePalette` → `ThemeDefinitions.swift`

**Design tokens** (`DesignTokens` enum, all sub-namespaces):
- Layout primitives: `CornerRadius`, `Spacing`, `Animation`, `Opacity`, `Shadow`, `Layout`, `Typography`
- Semantic: `SemanticColors` (success/warning/error/info)
- Component-level: `Component.Button`, `.Card`, `.Input`, `.List`, `.Toolbar`, `.Modal`
- Presets: `AnimationPreset`, `TransitionPreset`, `SpacingScale`

**ViewModifiers** (`Design/ViewModifiers.swift`):
Reuse `CardStyleModifier`, `ButtonStyleModifier`, `IconButtonStyleModifier`, `ShimmerModifier`,
`TooltipModifier`, `TextStyleModifier`, `BackgroundModifier`, `BorderModifier` before writing inline styling.

**Patterns**: MVVM with `@AppStorage`/`@State`; `MarkdownParsing` protocol for testability;
spacing via `NSParagraphStyle` (never literal newlines).

## Code Style

- Swift 6 strict concurrency; `@MainActor` for all UI.
- 4-space indent, 120-char max line (SwiftFormat enforced).
- File headers — two spaces after `//`:
  ```swift
  //
  //  FileName.swift
  //  mdviewer
  //
  ```
- `internal` is the default access level; only add `public`/`private`/`fileprivate` when meaningful.

## SwiftLint / SwiftFormat

- `just format-fix` runs first; `just lint-fix` after.
- `trailing_comma` and `opening_brace` are **intentionally disabled** in SwiftLint — they conflict with SwiftFormat output. Do not re-enable them.
- **`just lint-fix` caution**: the trailing-closure auto-fix can corrupt `contains(where: { ... }) ?? value` patterns (drops the space before `??`, causing a parse error). Always run `just build` after `just lint-fix`.
- Single-char identifiers (`r`, `g`, `b`, `a`, `c`, `f`, `d`, `h`, `l`, `x`, `y`, `i`, `j`, `k`) are excluded from `identifier_name`. Add new ones to `.swiftlint.yml` if needed.

## Testing

Tests live in `mdviewer/Tests/mdviewerTests/`. 287 tests across:
design system, frontmatter parsing, markdown rendering, visual regression,
syntax highlighting, E2E, performance, and spacing stability.

Iteration rule:
- Use the smallest relevant test command first (`swift test --filter <TestName>`, `just test-unit`, `just test-visual`, etc.).
- If a specific test fails, rerun only that test after each fix until it passes.
- Do not rerun `just test` or `just quality` after every small change.
- When implementing or changing a feature for interactive verification, run `just install-open` after each iteration unless the user explicitly says not to.
- Run the full `just quality` gate only once, immediately before commit.

Watch for regressions:
- Double spacing in rendered output (→ `BlockSeparatorInjector`)
- Theme color fidelity in light and dark mode
- Bounds checking on `NSString`/`NSAttributedString` character access
