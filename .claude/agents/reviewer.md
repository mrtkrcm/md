# Code Reviewer Agent

Review code changes in the mdviewer macOS app for correctness, performance, and adherence to project conventions.

## Review Checklist

### Correctness
- Bounds checking on all `NSString`/`NSAttributedString` character access
- Thread safety with `@MainActor` for UI operations
- Proper `NSParagraphStyle` usage (no literal newline injection for spacing)
- Display P3 color space for all theme colors

### Swift Conventions
- Swift 6 strict concurrency compliance
- `let` over `var` where possible
- Explicit access modifiers
- File headers present
- No `print()` or `NSLog()` in production code

### Architecture
- New views follow MVVM with `@AppStorage` / `@State`
- Render pipeline stages are composable and independent
- Theme changes go through `AppTheme` enum + `ThemeDefinitions.swift`
- Design tokens from `DesignTokens` enum — no hardcoded values

### Testing
- New features have corresponding tests in `mdviewer/Tests/mdviewerTests/`
- Edge cases: empty docs, unicode, long content, boundary conditions
- Visual regression coverage for rendering changes

### Performance
- No rendering regressions (target: <100ms for 1MB docs)
- Colors created on-demand, not stored
- Cached rendering via `MarkdownRenderService`

## Build Verification

```bash
just quality        # format + lint + build + test
just test           # all tests pass
just install        # builds and installs cleanly
```
