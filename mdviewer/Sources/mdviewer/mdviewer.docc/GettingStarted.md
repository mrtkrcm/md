# Getting Started

Learn how to build and run mdviewer from source.

## Requirements

- macOS 14.0 or later
- Xcode 16.0 or later (or Swift 6.0+)
- 4GB RAM minimum

## Building from Source

### Using Just (Recommended)

```bash
# Clone the repository
git clone https://github.com/yourusername/mdviewer.git
cd mdviewer

# Install dependencies
just install-deps

# Build the app
just build-app

# Run tests
just test

# Install to /Applications
just install
```

### Using Swift Package Manager

```bash
cd mdviewer
swift build
swift test
```

### Using Xcode

1. Open `mdviewer/Package.swift` in Xcode
2. Select the `mdviewer` scheme
3. Build and run (⌘R)

## Development Workflow

### Running

```bash
just run              # Run from source
just debug            # Run with debug output
```

### Testing

```bash
just test             # Unit tests
just test-e2e         # End-to-end tests
just test-coverage    # With coverage report
```

### Code Quality

```bash
just quality          # Full quality check
just format-fix       # Fix formatting
just lint-fix         # Fix linting issues
```

## Configuration

### Preferences

mdviewer stores preferences in `~/Library/Preferences/com.yourcompany.mdviewer.plist`:

- `theme`: Selected color theme
- `readerFontSize`: Font size for reading
- `readerColumnWidth`: Column width for reading
- `syntaxPalette`: Code highlighting theme

### Custom Themes

Themes are defined in ``ThemeDefinitions``. To add a custom theme:

1. Create a new `NativeThemePalette`
2. Add to ``AppTheme`` enum
3. Register in ``DesignTokens``

## Troubleshooting

### Build Failures

```bash
just clean            # Clean build artifacts
just install-deps     # Reinstall dependencies
```

### Permission Issues

If the app won't open:
1. Right-click → Open
2. Click "Open" in the dialog
3. Or: System Preferences → Security → Open Anyway

## Next Steps

- Read about the <doc:Architecture>
- Learn about the <doc:RenderingPipeline>
- Explore the <doc:DesignTokens>
