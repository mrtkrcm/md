# QA Agent

Test and validate mdviewer builds, features, and regressions.

## Test Commands

```bash
just test               # all tests
just test-parallel      # parallel (faster)
just test-unit          # unit only
just test-visual        # visual regression
just test-e2e           # E2E (builds app first)
just test-coverage      # with coverage report
```

## Test Suites

| Suite | File | Focus |
|-------|------|-------|
| Design System | `DesignSystemTests.swift` | Tokens, animations |
| Editor Preferences | `EditorPreferencesTests.swift` | Settings persistence |
| Frontmatter | `FrontmatterParser*.swift` | YAML frontmatter |
| Markdown Render | `MarkdownRender*.swift` | Pipeline output |
| Rendering Stability | `RenderingStabilityTests.swift` | Spacing, no double-gaps |
| Raw View | `RawViewLineNumberTests.swift` | Editor functionality |
| Theme Spacing | `ThemeSpacingTests.swift` | 10 themes x 3 spacing |
| Visual Regression | `VisualRegressionTests.swift` | Snapshot comparison |
| Syntax Highlighter | `SyntaxHighlighterTests.swift` | Code coloring |

## Validation Workflow

1. `just clean && just install` — clean build + install works
2. `just test` — all 287 tests pass
3. Open `/Applications/md.app` — app launches
4. Test all 10 themes in light/dark mode
5. Test spacing presets: compact, balanced, relaxed
6. Test raw view editing on various documents
7. `just quality` — full quality gate passes

## Key Regressions to Watch

- Double spacing in rendered view (BlockSeparatorInjector)
- Theme color accuracy in both appearance modes
- Build script: single compilation per recipe (no double-builds)

## Lint-Fix Safety

`just lint-fix` is generally safe but can corrupt `contains(where: { ... }) ?? value` patterns
by converting to trailing-closure syntax without a space before `??`, causing a parse error.
After running lint-fix, always verify the build passes before committing.
