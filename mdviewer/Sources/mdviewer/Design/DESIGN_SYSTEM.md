# mdviewer Design System

Modern, cohesive design patterns for liquid design-inspired interface.

## Architecture Overview

```
Design System
├── DesignTokens.swift (values: spacing, colors, durations)
├── TransitionKit.swift (animations & transitions)
└── ViewModifiers.swift (reusable interactive modifiers)
```

## Core Principles

### 1. **Design Tokens First**
All design decisions use centralized tokens from `DesignTokens` enum:
- Never hardcode spacing, colors, or durations
- Use semantic naming (`relaxed`, `standard`, `compact`)
- Update system-wide by changing token values

### 2. **Modern Swift Patterns**
- Use `@available` for iOS 17+ / macOS 15+ features with fallbacks
- Leverage `.smooth()` animation when available
- Prefer `withAnimation` for explicit control
- Use `@FocusState` for accessibility

### 3. **Animation Philosophy**
- Fast: 0.15s for micro-interactions
- Normal: 0.22s for standard transitions
- Slow: 0.3s for emphasis
- Always use `easeOut` for appearance, `easeIn` for dismissal

## Component Animations

### Content Transitions

```swift
// Fade in/out
.transition(.opacity)

// Scale with fade (appearance)
.transition(.scale.combined(with: .opacity))

// Elegant slide from edge
.transition(AnyTransition.elegantSlide(from: .leading))

// Popup with bounce
.transition(.popupScale)
```

### Interactive Elements

```swift
// Hover + press feedback
.interactive()

// Context-aware animation
.contextualSpring(isHovered)

// Elevation with shadow
.elevation(.standard)
```

### Loading States

```swift
// Show loading indicator
.loading(isLoading)

// Smooth visibility toggle
.smoothVisibility(isVisible)
```

## View Modifier Hierarchy

### Applied Order
1. **Content** (core structure)
2. **Styling** (colors, fonts, opacity)
3. **Layout** (frame, padding, alignment)
4. **Interaction** (gestures, focus)
5. **Animation** (transitions, state-driven animation)
6. **Accessibility** (focus rings, labels)

### Example Pattern

```swift
MyView()
    // 1. Content structure
    
    // 2. Styling
    .foregroundStyle(.primary)
    .font(.system(.body, design: .default))
    
    // 3. Layout
    .frame(maxWidth: .infinity)
    .padding(DesignTokens.Spacing.standard)
    
    // 4. Interaction
    .interactive()
    .onTapGesture { action() }
    
    // 5. Animation
    .transition(.smoothFade)
    .smoothAnimation(state)
    
    // 6. Accessibility
    .accessibilityLabel("Label")
    .modernFocusRing()
```

## Animation Timing Reference

| Duration | Use Case | Code |
|----------|----------|------|
| 0.15s (Fast) | Button press, micro-feedback | `DesignTokens.Animation.fast` |
| 0.22s (Normal) | View transitions, state changes | `DesignTokens.Animation.normal` |
| 0.25s (Medium) | Content reflow, size changes | `DesignTokens.Animation.medium` |
| 0.3s (Slow) | Emphasis, entrance animations | `DesignTokens.Animation.slow` |

## Spring Animation Presets

### Responsive Spring (Interactive)
```swift
.spring(response: 0.28, dampingFraction: 0.82)
// Quick, slightly bouncy - good for buttons
```

### Bouncy Spring (Playful)
```swift
.spring(response: 0.35, dampingFraction: 0.7)
// More bounce, playful feel - good for dialogs
```

### Stiff Spring (Quick)
```swift
.spring(response: 0.2, dampingFraction: 0.9)
// Quick, minimal bounce - good for urgent feedback
```

## Spacing System

| Token | Size | Usage |
|-------|------|-------|
| `tight` | 4pt | Internal component padding |
| `compact` | 6pt | Related elements |
| `standard` | 8pt | Default spacing |
| `comfortable` | 10pt | Breathing room |
| `relaxed` | 12pt | Group separation |
| `wide` | 14pt | Section boundaries |
| `large` | 18pt | Major sections |
| `extraLarge` | 24pt | Top-level padding |

## Opacity Scale

| Token | Value | Usage |
|-------|-------|-------|
| `verySubtle` | 4% | Borders, very light backgrounds |
| `subtle` | 5% | Hover states |
| `light` | 6% | Secondary text (disabled state) |
| `mediumLight` | 8% | Dividers |
| `medium` | 10% | Secondary UI elements |
| `mediumHigh` | 12% | Loading indicators |
| `high` | 15% | Overlays, shadows |
| `veryHigh` | 50% | Modal backgrounds |

## Color System Integration

Use `NativeThemePalette` for theme-aware colors:
- `textPrimary` - Main text
- `textSecondary` - Secondary text
- `codeBackground` - Code blocks
- `heading` - Headings
- `blockquoteAccent` - Quote styling

## Modern Swift 6 Practices

### Use Internal Imports
```swift
internal import SwiftUI
internal import Foundation
```

### Avoid Type Erasure When Possible
```swift
// Bad
func myView() -> AnyView { ... }

// Good
@ViewBuilder
func myView() -> some View { ... }
```

### Use @State Wisely
```swift
// In NSViewRepresentable Coordinator
@State private var isLoading: Bool
// Instead of @ObservedObject or complex state management
```

### Leverage Environment
```swift
@Environment(\.preferences) private var preferences
// Instead of passing through multiple levels
```

## Transition Guidelines

### Entrance Animations (Appear)
- Use `easeOut` for smooth arrival
- Combine with scale (0.95 → 1.0) for depth
- Duration: 0.22s normal

### Exit Animations (Disappear)
- Use `easeIn` for quick departure
- Duration: 0.15s fast

### State Changes (Toggle)
- Use spring for interactive feedback
- Use `smooth()` (iOS 17+) for non-interactive

## Performance Considerations

1. **Limit Simultaneous Animations**
   - Max 3-4 overlapping animations
   - Stagger complex transitions

2. **Use Appropriate Durations**
   - Don't use 0.3s+ for frequently-triggered animations
   - Reserve slow animations for infrequent state changes

3. **Avoid Animating Expensive Properties**
   - Animate scale, opacity, translation
   - Avoid animating frame size (use fixed layout)

4. **Test on Older Hardware**
   - Spring animations are GPU-intensive
   - Provide easeInOut fallbacks

## Testing Animations

```swift
// In tests, disable animations
#if DEBUG
    UIView.setAnimationsEnabled(false)
#endif

// Verify state changes (animations happen in background)
XCTAssertEqual(state.property, expectedValue)
```

## Future Enhancements

- [ ] Implement `KeyframeAnimator` for sequenced animations (iOS 17+)
- [ ] Add `PhaseAnimator` for complex entrance sequences
- [ ] Explore `Canvas` for custom animated backgrounds
- [ ] Consider `TimelineView` for real-time animations
- [ ] Implement gesture-driven animations (swipe, scroll tracking)

## Resources

- [Apple Design System](https://design.apple.com/)
- [Interaction Principles](https://developer.apple.com/design/human-interface-guidelines/)
- [SwiftUI Animations](https://developer.apple.com/wwdc22/10054)
- [Modern Swift Patterns](https://developer.apple.com/wwdc23)

---

*Last Updated: 2026-02-26*
