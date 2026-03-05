# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Interactive Table of Contents** - New sidebar "Outline" tab for bidirectional document navigation
- **2026 Liquid Design Infrastructure** - Native lensing materials, refractive mesh gradients, and corner concentricity
- **Semantic Accessibility Hierarchy** - Native VoiceOver support for headings, lists, and tables via `NSAccessibilityElement`
- **Modern SF Symbol Effects** - Integrated `.rotate`, `.pulse`, and `.bounce` effects for interactive controls
- **120fps Optimized Rendering** - Geometry-aware decoration caching and $O(N \log N)$ attribute scanning for ProMotion displays
- **Startup Speed Optimizations** - Background service pre-warming and Frontmatter parsing caching
- **macOS 15+ Support** - Upgraded deployment target to leverage latest system APIs

### Changed
- Migrated legacy "frosted glass" materials to modern refractive `glassEffect` system
- Unified Markdown render pipeline into a single-pass efficient injector
- Improved toolbar transition smoothness with velocity-aware animations
- Enhanced E2E test suite with robust accessibility fallbacks

## [1.0.1-stable] - 2026-02-26

### Fixed
- Rendered view double spacing (BlockSeparatorInjector injecting newlines + TypographyApplier paragraph spacing)
- Raw view line number crash (out-of-bounds character access in LineNumberRulerView)
- Raw view text visibility (background color disabled)

### Added
- 10 standardized themes: Basic, GitHub, DocC, Solarized, Gruvbox, Dracula, Monokai, Nord, One Dark, Tokyo Night
- Light/dark mode for all themes (Display P3 color space)
- 3 spacing presets: compact (1.5x), balanced (1.65x), relaxed (1.8x)
- Comprehensive test suites: RenderingStability, RawViewLineNumber, ThemeSpacing (26 tests)
- SwiftFormat configuration (70+ rules), SwiftLint (100+ rules)
- GitHub Actions CI with code coverage
- Lefthook pre-commit hooks
- Justfile for task automation
- E2E test automation
- Security audit workflow

## [1.0.0] - 2024-XX-XX

### Added
- Initial release of mdviewer
- Liquid design system with fluid animations
- Floating UI components (metadata, toolbar)
- Glass panel effects and design tokens
- Markdown rendering pipeline
- Syntax highlighting for code blocks
- Reader layout with typography system
- Preferences system with type-safe storage
- E2E testing with AppleScript
- Visual regression tests
