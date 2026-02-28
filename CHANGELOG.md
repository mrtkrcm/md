# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Refactored Justfile: clear, non-overlapping recipes (`build`, `release`, `package`, `install`, `install-open`)
- Eliminated double-builds from previous `build`/`build-release` recipes
- Enhanced `scripts/build.sh` with colored stage output, timing, `--skip-build`, `--quiet` flags
- Added post-install verification (binary, Info.plist, codesign checks)
- Simplified `scripts/install.sh`: tests off by default, binary freshness detection

## [1.0.1-stable] - 2026-02-26

### Fixed
- Rendered view double spacing (BlockSeparatorInjector injecting newlines + TypographyApplier paragraph spacing)
- Raw view line number crash (out-of-bounds character access in LineNumberRulerView)
- Raw view text visibility (background color disabled)

### Added
- 10 standardized themes: Basic, GitHub, DocC, Solarized, Gruvbox, Dracula, Monokai, Nord, One Dark, Tokyo Night
- Light/dark mode support for all themes (Display P3 color space)
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
