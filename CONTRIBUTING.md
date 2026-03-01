# Contributing

## Setup

```bash
git clone https://github.com/mrtkrcm/mdviewer.git
cd mdviewer
just install-deps   # SwiftFormat, SwiftLint, Lefthook
just setup-hooks    # pre-commit hooks
```

## Development Workflow

### Building

```bash
just build          # debug (fast iteration)
just release        # release build only
just install        # build + package + install to /Applications
just install-open   # same + launch
```

### Testing

```bash
just test           # all tests
just test-parallel  # parallel execution
just test-e2e       # E2E (builds app first)
just test-coverage  # with coverage report
```

### Code Quality

```bash
just quality        # full gate: format + lint + build + test
just format-fix     # auto-fix formatting
just lint-fix       # auto-fix lint
```

## Code Style

- SwiftFormat enforced (4-space indent, 120 char max line)
- Swift 6 strict concurrency
- Prefer `let` over `var`
- File headers (two spaces after `//`):
  ```swift
  //
  //  FileName.swift
  //  mdviewer
  //
  ```
- `trailing_comma` and `opening_brace` SwiftLint rules are intentionally disabled — they conflict with SwiftFormat's output
- After `just lint-fix`, verify `just build` still passes (trailing-closure rewrites can break `?? expr` patterns)

## Commit Messages

[Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add liquid background animation
fix(parser): handle empty frontmatter
refactor!: simplify render pipeline
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

## Pull Requests

1. Branch from `main`: `git checkout -b feature/my-feature`
2. Make changes with tests
3. Pass quality gate: `just quality`
4. Commit with conventional message
5. Open PR

### Checklist

- [ ] Tests added/updated
- [ ] `just quality` passes
- [ ] Commit messages follow conventions
- [ ] Docs updated if needed

## Architecture

```
mdviewer/Sources/mdviewer/
├── Models/          # Data models and preferences
├── Views/           # SwiftUI views + AppKit components
│   ├── Components/  # Reusable UI
│   ├── Editor/      # Raw markdown editing
│   └── Layout/      # Layout managers
├── Services/        # Business logic
│   └── Pipeline/    # Markdown render pipeline
├── Theme/           # Design tokens and theming
└── Syntax/          # Syntax highlighting
```

### Key Patterns

- **MVVM**: Views observe models via `@AppStorage` and `@State`
- **Protocol-Oriented**: `MarkdownParsing` protocol for testability
- **Pipeline**: Markdown rendering uses composable stages (parse, separate, style, highlight)
- **Design Tokens**: All spacing/colors/durations via `DesignTokens` enum
