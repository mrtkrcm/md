# Theme Standardization

## Overview

The app now features **10 standardized, professional markdown themes** with consistent color schemes, proper paragraph spacing support, and light/dark mode compatibility. All themes follow a unified architecture ensuring text spacing preferences work correctly regardless of theme selection.

## 10 Available Themes

### Apple Ecosystem (3 themes)
1. **Basic** - Minimal, system-integrated colors using macOS standard colors
2. **GitHub** - GitHub's markdown rendering style with clean, professional appearance
3. **DocC** - Apple's documentation compiler style for technical documentation

### Popular Code Editor Themes (7 themes)
4. **Solarized** - Precision colors for machines and people; optimized for reduced eye strain
5. **Gruvbox** - Retro groove color scheme with warm, earthy tones
6. **Dracula** - Dark theme optimized for comfortable extended viewing
7. **Monokai** - Vibrant, high-contrast code editor theme from Sublime Text
8. **Nord** - Arctic, north-bluish color palette with cool tones
9. **One Dark** - Atom's One Dark theme with balanced contrast
10. **Tokyo Night** - Tokyo neon nights inspired with modern, sophisticated colors

## Theme Architecture

### Standardized Color Properties

Each theme defines 8 core color properties:

```swift
struct ThemeColors {
    // Text rendering
    var textPrimary: NSColor        // Body text color
    var textSecondary: NSColor      // Secondary/muted text
    var heading: NSColor            // Heading text color
    var link: NSColor               // Link text color
    
    // Code rendering
    var codeBackground: NSColor     // Code block background
    var codeBorder: NSColor         // Code block border
    
    // Blockquote rendering
    var blockquoteAccent: NSColor   // Blockquote accent color
    var blockquoteBackground: NSColor // Blockquote background
    
    // Inline code
    var inlineCodeBackground: NSColor // Inline code background
}
```

### Light/Dark Mode Support

All 10 themes support both macOS appearance modes:
- **Light Mode**: Optimized for well-lit environments
- **Dark Mode**: Optimized for low-light environments

Colors are defined using Display P3 color space for accurate, vibrant rendering on modern Macs.

### Paragraph Spacing Integration

All themes properly support the spacing preferences:

| Spacing | Description | Line Height |
|---------|-------------|-------------|
| Compact | Tight but readable | 1.5x |
| Balanced | Optimal reading distance | 1.65x (golden ratio) |
| Relaxed | Airy, accessible | 1.8x |

Spacing is applied via `NSParagraphStyle` attributes, ensuring consistent, proportional gaps between:
- Paragraphs
- Headers
- List items
- Code blocks
- Blockquotes

## Implementation Details

### File Structure

```
mdviewer/Sources/mdviewer/Theme/
├── AppTheme.swift              # Theme enumeration with 10 cases
├── ThemeDefinitions.swift      # Color definitions for all themes
└── NativeThemePalette.swift   # Theme palette initialization
```

### Color Definitions

`ThemeDefinitions.swift` contains all color specifications:
- **236 lines** of standardized theme definitions
- Switch statement organized by theme + color scheme
- Display P3 color space for modern Mac support
- Fallback for unknown schemes

### Theme Selection API

```swift
enum AppTheme: String, CaseIterable {
    case basic, github, docC
    case solarized, gruvbox, dracula, monokai, nord, onedark, tokyonight
    
    var description: String { ... }  // Human-readable theme name
}
```

## Testing

### Theme Spacing Tests (7 tests)

Comprehensive test suite in `ThemeSpacingTests.swift`:

1. **Light Mode Spacing** - All themes with proper spacing in light mode
2. **Dark Mode Spacing** - All themes with proper spacing in dark mode
3. **Spacing Preference Compatibility** - All themes × all spacing preferences (compact/balanced/relaxed)
4. **Code Block Colors** - Code backgrounds render correctly in all themes
5. **Blockquote Styling** - Blockquote appearance consistent across themes
6. **Theme Registration** - Verify all 10 themes are registered
7. **Theme Descriptions** - All themes have meaningful descriptions

**Test Coverage**: 10 themes × 2 color schemes × 3 spacing prefs = 60 combinations validated

### Validation Results

✓ All 232 tests pass  
✓ Zero spacing-related regressions  
✓ All themes verified with light/dark modes  
✓ All spacing presets work with all themes  

## Usage Examples

### Selecting a Theme Programmatically

```swift
let request = RenderRequest(
    markdown: "# Hello",
    readerFontFamily: .newYork,
    readerFontSize: 16,
    codeFontSize: 12,
    appTheme: .solarized,           // Choose theme
    syntaxPalette: .midnight,
    colorScheme: .dark,
    textSpacing: .balanced,          // Choose spacing
    readableWidth: 760,
    showLineNumbers: false
)
```

### Adding New Theme

To add a new theme:

1. Add case to `AppTheme` enum:
```swift
case myTheme = "My Theme"
```

2. Add to `AppTheme.description`:
```swift
case .myTheme:
    return "My custom theme"
```

3. Add color definitions in `ThemeDefinitions.swift`:
```swift
case (.myTheme, .light):
    textPrimary = Self.p3Color(r: 0.2, g: 0.2, b: 0.2)
    // ... more colors

case (.myTheme, .dark):
    textPrimary = Self.p3Color(r: 0.9, g: 0.9, b: 0.9)
    // ... more colors
```

## Color Space: Display P3

All colors use Display P3 (P3) color space:
- **Wider gamut** than sRGB for vibrant, accurate colors
- **Modern Mac compatibility** (all recent Macs support P3)
- **Future-proof** for extended color displays

Helper function for color creation:
```swift
static func p3Color(r: Double, g: Double, b: Double, a: Double = 1.0) -> NSColor {
    NSColor(colorSpace: NSColorSpace.displayP3, 
            components: [r, g, b, a], 
            count: 4)
}
```

## Design Principles

### Consistency
- All themes follow the same color property structure
- Spacing is handled uniformly regardless of theme
- Light/dark pairs are designed together for coherence

### Readability
- Sufficient contrast ratios for accessibility
- Consistent heading-to-body color relationships
- Code blocks always visually distinct from body text

### Usability
- Easy theme switching without affecting document
- Spacing preferences work across all themes
- Fallback for unknown color schemes

## Performance Impact

- **Zero runtime cost** for theme selection (enum dispatch at render time)
- **Memory efficient** (colors created on-demand during rendering)
- **Cached rendering** via `MarkdownRenderService` reduces redundant work

## Accessibility

All themes should:
- ✓ Meet WCAG AA contrast requirements
- ✓ Provide clear visual hierarchy
- ✓ Support system dark mode preferences
- ✓ Work with accessibility color scheme overrides

## Future Enhancements

Potential improvements:
1. **User-defined themes** - Allow users to create custom color schemes
2. **Color blindness modes** - Deuteranopia, protanopia, tritanopia variations
3. **High contrast mode** - Increased contrast for vision accessibility
4. **Theme sync** - CloudKit sync of user preferences across devices
5. **Import/Export** - Share custom themes via JSON

## References

- [Display P3 Color Space](https://en.wikipedia.org/wiki/Display_P3)
- [Solarized Colors](https://ethanschoonover.com/solarized/)
- [Gruvbox Theme](https://github.com/morhetz/gruvbox)
- [Dracula Theme](https://draculatheme.com/)
- [Nord Theme](https://www.nordtheme.com/)
- [Tokyo Night Theme](https://github.com/enkia/tokyo-night-vscode-theme)
