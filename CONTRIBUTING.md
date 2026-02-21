# Contributing to mdviewer

Thank you for your interest in contributing to mdviewer! This document provides guidelines and instructions for contributing.

## Development Setup

### Prerequisites

- macOS 14.0+
- Xcode 16.0+ or Swift 6.0+
- [Homebrew](https://brew.sh)

### Initial Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/mdviewer.git
cd mdviewer
```

2. Install dependencies:
```bash
just install-deps
```

3. Setup git hooks:
```bash
just setup-hooks
```

## Development Workflow

### Building

```bash
just build              # Debug build
just build-release      # Release build
just build-app          # Full macOS app bundle
```

### Testing

```bash
just test               # Run all tests
just test-coverage      # Run with coverage
just test-e2e          # Run E2E tests
```

### Code Quality

```bash
just quality            # Run all quality checks
just format-fix         # Fix formatting
just lint-fix           # Fix lint issues
```

## Code Style

### Swift Style Guide

- Follow the existing code style (enforced by SwiftFormat)
- Use 4 spaces for indentation
- Maximum line length: 120 characters
- Use Swift 6 strict concurrency
- Prefer `let` over `var`
- Use explicit access modifiers

### Commit Messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style (formatting, semicolons, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or fixing tests
- `build`: Build system changes
- `ci`: CI/CD changes
- `chore`: Maintenance tasks

Examples:
```
feat: add liquid background animation
fix(parser): handle empty frontmatter
docs: update API documentation
refactor!: simplify render pipeline
```

### File Headers

All source files should include a header:

```swift
//
//  FileName.swift
//  mdviewer
//
```

## Pull Request Process

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make your changes with tests
3. Ensure all quality checks pass: `just quality`
4. Commit with conventional commit message
5. Push to your fork
6. Open a Pull Request

### PR Checklist

- [ ] Tests added/updated
- [ ] Code follows style guide
- [ ] SwiftFormat passes
- [ ] SwiftLint passes
- [ ] Commit messages follow conventions
- [ ] Documentation updated (if needed)

## Architecture

### Project Structure

```
mdviewer/Sources/mdviewer/
├── Models/          # Data models and business logic
├── Views/           # SwiftUI views
│   ├── Components/  # Reusable UI components
│   ├── Editor/      # Text editing
│   └── Layout/      # Layout managers
├── Services/        # Business logic services
│   └── Pipeline/    # Markdown render pipeline
├── Theme/           # Design tokens and theming
└── Syntax/          # Syntax highlighting
```

### Key Patterns

- **MVVM**: Views observe models via `@AppStorage` and `@State`
- **Protocol-Oriented**: Services define protocols for testability
- **Actor Isolation**: Services use actors for thread safety
- **Pipeline**: Markdown rendering uses composable stages

## Testing

### Unit Tests

Located in `mdviewer/Tests/mdviewerTests/`. Test files should match the pattern `*Tests.swift`.

### E2E Tests

Located in `scripts/e2e.sh`. Uses AppleScript for UI automation.

### Visual Regression Tests

Located in `mdviewer/Tests/mdviewerTests/VisualRegressionTests.swift`.

## Questions?

Feel free to open an issue for questions or discussion.
