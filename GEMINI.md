# GEMINI.md - Project Context: mdviewer

## Project Overview
`mdviewer` is a high-performance, native macOS Markdown viewer built with **SwiftUI** and an **AppKit-backed rendering pipeline**. It is designed for the 2026 "Liquid Design" era, supporting macOS 15+ features, ProMotion (120Hz) displays, and deep accessibility integration.

- **Primary Goal**: Provide a fluid, "alive" reading and editing experience for Markdown documents.
- **Key Technologies**: Swift 6, SwiftUI, AppKit (TextKit 1), Just (command runner), XCTest.
- **Target Platform**: macOS 15.0+ (Universal).

## Architecture & Pipeline
The application uses a modular rendering pipeline to transform raw Markdown into rich typography:

1.  **MarkdownDocument**: Standard `ReferenceFileDocument` handling loading and encoding.
2.  **MarkdownRenderService**: An actor-based orchestrator that manages the pipeline and caches results.
3.  **The Pipeline (`Services/Pipeline/`)**:
    *   `MarkdownParser`: Converts text to attributed strings with semantic intents.
    *   `BlockSeparatorInjector`: Single-pass injection of newlines and indents.
    *   `SyntaxHighlighter`: Regex-based highlighting for 20+ languages.
    *   `TypographyApplier`: Unified pass for fonts, kerning, and structural markers.
4.  **The View Layer**:
    *   `ReaderTextView`: Custom `NSTextView` subclass optimized for 120fps scrolling via `decorationCache`.
    *   `NativeMarkdownTextView`: `NSViewRepresentable` bridge with rendering generation tracking.
    *   `InspectorSidebar`: Multi-mode panel (Outline/ToC, Metadata, Folder).

## Building and Running
The project uses `just` for task automation.

| Command | Action |
| :--- | :--- |
| `just build` | Debug build |
| `just run` | Launch debug version |
| `just test` | Run all unit/integration tests (491 tests) |
| `just test-e2e` | Run AppleScript-based end-to-end tests |
| `just install` | Build and install to `/Applications/md.app` |
| `just quality` | Full gate (Format + Lint + Build + Test) |

## Development Conventions

### 1. Performance (The "120fps" Rule)
- Always use `enumerateAttribute` instead of manual linear loops for string scanning.
- Complex geometry (backgrounds, borders) must be cached in `ReaderLayoutManager`'s `decorationCache`.
- Avoid heavy computation in SwiftUI `body` blocks; use `@State` caching or background tasks (e.g., `FrontmatterParser`).

### 2. Design Language (Liquid Design 2026)
- **Materials**: Use `.glassEffect(.regular)` and avoid manual Gaussian blurs.
- **Concentricity**: Use the `liquidCornerRadius` helper for nested elements.
- **Motion**: Animations should be physical/bouncy but must respect `accessibilityReduceMotion`.

### 3. Accessibility
- All semantic elements (headings, lists, tables) must be exposed via `NSAccessibilityElement` subclasses (e.g., `AccessibilityHeading`).
- Use `AccessibilityAnnouncement` for async state changes (e.g., "Document Loaded").

### 4. Code Standards
- **Imports**: Use `internal import` for internal modules.
- **Tooling**: `SwiftFormat` and `SwiftLint` are enforced via `Lefthook` pre-commit hooks.
- **Testing**: Every rendering change must be verified by `MarkdownRenderVisualTests` and `MarkdownRenderIntegrationTests`.
