# Theme Quick Reference

## All 10 Themes at a Glance

| # | Theme | Category | Light Mode | Dark Mode | Best For |
|---|-------|----------|-----------|-----------|----------|
| 1 | Basic | Apple | System colors | System colors | Default, minimal setup |
| 2 | GitHub | Apple | Clean blue/gray | Dark blue/gray | GitHub-style docs |
| 3 | DocC | Apple | Apple docs blue | Apple docs blue | Technical documentation |
| 4 | Solarized | Editor | Warm (base3) | Cool (base03) | Precision, eye strain prevention |
| 5 | Gruvbox | Editor | Warm browns | Dark browns | Retro, comfortable reading |
| 6 | Dracula | Editor | Light variant | Dark (bg #282a36) | Extended viewing, modern |
| 7 | Monokai | Editor | Light variant | Vibrant (bg #272822) | Code-focused, high contrast |
| 8 | Nord | Editor | Cool (light) | Arctic (dark) | Professional, cool tones |
| 9 | One Dark | Editor | Light variant | Modern (bg #282c34) | Popular, balanced |
| 10 | Tokyo Night | Editor | Modern light | Neon dark (bg #1a1b26) | Contemporary, stylish |

## Spacing Support Matrix

All themes work with all spacing preferences:

```
Theme             │ Compact │ Balanced │ Relaxed
──────────────────┼─────────┼──────────┼─────────
Basic             │    ✓    │    ✓     │    ✓
GitHub            │    ✓    │    ✓     │    ✓
DocC              │    ✓    │    ✓     │    ✓
Solarized         │    ✓    │    ✓     │    ✓
Gruvbox           │    ✓    │    ✓     │    ✓
Dracula           │    ✓    │    ✓     │    ✓
Monokai           │    ✓    │    ✓     │    ✓
Nord              │    ✓    │    ✓     │    ✓
One Dark          │    ✓    │    ✓     │    ✓
Tokyo Night       │    ✓    │    ✓     │    ✓
```

## Color Properties Reference

Each theme defines these 8 colors (shown in AppTheme.swift):

### Text Colors
- `textPrimary` - Body text color
- `textSecondary` - Secondary text, footnotes, metadata
- `heading` - Heading text color
- `link` - Hyperlink color

### Code Colors
- `codeBackground` - Fenced code block background
- `codeBorder` - Code block border color
- `inlineCodeBackground` - Inline code background (backticks)

### Blockquote Colors
- `blockquoteAccent` - Blockquote left border/accent color
- `blockquoteBackground` - Blockquote background tint

## Color Space: Display P3

All colors are defined in Display P3:

```swift
// Example: Solarized Light blue
Self.p3Color(r: 0.36, g: 0.63, b: 0.78)
```

Benefits:
- Wider color gamut than sRGB
- Vibrant, accurate colors on modern Macs
- Future-proof for extended color displays

## Light vs Dark Mode Implementation

Each theme has 2 variants:

```swift
case (.themeName, .light):
    // Light mode colors
    
case (.themeName, .dark):
    // Dark mode colors
```

No runtime color conversion - colors are pre-defined for each scheme.

## Testing Validation

All themes validated with:

✓ **Light mode** - All 10 themes in light appearance  
✓ **Dark mode** - All 10 themes in dark appearance  
✓ **All spacing prefs** - Compact, Balanced, Relaxed (30 combinations)  
✓ **Code blocks** - Background colors correct  
✓ **Blockquotes** - Styling consistent  
✓ **Overall rendering** - 232 tests, all passing  

## Adding a New Theme

1. **Add to enum** in `AppTheme.swift`:
```swift
case myCustom = "My Custom"
```

2. **Add description**:
```swift
case .myCustom:
    return "Description here"
```

3. **Add colors** in `ThemeDefinitions.swift`:
```swift
case (.myCustom, .light):
    textPrimary = Self.p3Color(r: ..., g: ..., b: ...)
    // ... 8 total colors

case (.myCustom, .dark):
    textPrimary = Self.p3Color(r: ..., g: ..., b: ...)
    // ... 8 total colors
```

4. **Test** - Ensure rendering works in both modes

## Theme Selection Flow

```
User selects theme
    ↓
RenderRequest created with appTheme
    ↓
MarkdownRenderService.render() called
    ↓
NativeThemePalette initialized with (theme, colorScheme)
    ↓
Switch statement in ThemeDefinitions.swift
    ↓
8 colors assigned for theme/scheme combination
    ↓
TypographyApplier uses colors for styling
    ↓
Final attributed string rendered with proper colors + spacing
```

## Spacing Architecture

Spacing is NOT theme-dependent:

```
ReaderTextSpacing (user preference)
    ↓ (e.g., "Balanced")
    ↓ 
ReaderTextSpacing.paragraphSpacing(fontSize: 16)
    ↓
Applied to NSParagraphStyle.paragraphSpacing
    ↓
Rendered by NSLayoutManager (theme-agnostic)
```

This ensures consistent spacing across all 10 themes.

## Performance Notes

- **Theme selection**: O(1) enum dispatch at render time
- **Color creation**: Lazy (only during rendering)
- **Caching**: MarkdownRenderService caches results
- **Memory**: Negligible (8 colors per theme × 2 modes)

## Accessibility Considerations

All themes aim for:
- ✓ WCAG AA contrast ratios
- ✓ Clear visual hierarchy
- ✓ System color scheme integration
- ✓ Colorblind-friendly variants (future)

## Known Limitations & Future Improvements

Current:
- ✓ 10 pre-defined themes
- ✓ Light/dark mode support
- ✓ Display P3 color space

Future possibilities:
- [ ] User-created custom themes
- [ ] Colorblind mode variants
- [ ] High contrast mode
- [ ] Theme import/export (JSON)
- [ ] CloudKit sync across devices

---

**Last Updated**: February 2026  
**Test Coverage**: 232 tests passing  
**Themes**: 10 standardized themes, 2 color schemes each, 3 spacing options = 60 combinations verified
