//
//  ViewModifiers.swift
//  mdviewer
//
//  Modern view modifiers for consistent styling and interaction patterns.
//

internal import SwiftUI

// MARK: - Interactive State Modifier

/// Tracks and applies visual feedback for interactive elements
struct InteractiveModifier: ViewModifier {
    @State private var isHovered = false
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .opacity(isPressed ? 0.8 : 1.0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

extension View {
    /// Applies interactive hover and press effects
    func interactive() -> some View {
        modifier(InteractiveModifier())
    }
}

// MARK: - Elevation Modifier

/// Applies depth through shadow and scale
struct ElevationModifier: ViewModifier {
    enum Level {
        case subtle
        case standard
        case elevated
    }

    let level: Level

    func body(content: Content) -> some View {
        content
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                y: shadowY
            )
    }

    private var shadowOpacity: Double {
        switch level {
        case .subtle: return 0.05
        case .standard: return 0.10
        case .elevated: return 0.15
        }
    }

    private var shadowRadius: CGFloat {
        switch level {
        case .subtle: return 4
        case .standard: return 8
        case .elevated: return 16
        }
    }

    private var shadowY: CGFloat {
        switch level {
        case .subtle: return 2
        case .standard: return 4
        case .elevated: return 8
        }
    }
}

extension View {
    /// Applies shadow elevation with appropriate depth
    func elevation(_ level: ElevationModifier.Level = .standard) -> some View {
        modifier(ElevationModifier(level: level))
    }
}

// MARK: - Focus Ring Modifier

/// Applies modern focus ring styling
struct FocusRingModifier: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium)
                    .stroke(
                        Color.blue.opacity(isFocused ? 1.0 : 0.0),
                        lineWidth: 2
                    )
                    .animation(.easeInOut(duration: 0.15), value: isFocused)
            )
    }
}

extension View {
    /// Applies accessible focus ring styling
    func modernFocusRing() -> some View {
        modifier(FocusRingModifier())
    }
}

// MARK: - Loading State Modifier

/// Displays a loading indicator overlay
struct LoadingModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1.0)

            if isLoading {
                ProgressView()
                    .scaleEffect(1.2, anchor: .center)
                    .transition(.popupScale)
            }
        }
    }
}

extension View {
    /// Shows a loading overlay when isLoading is true
    func loading(_ isLoading: Bool) -> some View {
        modifier(LoadingModifier(isLoading: isLoading))
    }
}

// MARK: - Conditional Styling Modifier

/// Conditionally applies different styling
extension View {
    /// Applies different styling based on condition
    @ViewBuilder
    func conditionalStyle(
        if condition: Bool,
        apply style: (Self) -> some View
    ) -> some View {
        if condition {
            style(self)
        } else {
            self
        }
    }
}

// MARK: - Gesture Feedback Modifier

/// Provides haptic feedback on interaction
struct GestureFeedbackModifier: ViewModifier {
    @Environment(\.isEnabled) var isEnabled

    enum FeedbackType {
        case light
        case medium
        case heavy
    }

    let type: FeedbackType

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                provideFeedback()
            }
    }

    private func provideFeedback() {
        #if os(macOS)
            NSSound.beep()
        #else
            let generator = UIImpactFeedbackGenerator(style: hapticStyle)
            generator.impactOccurred()
        #endif
    }

    #if !os(macOS)
        private var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch type {
            case .light: return .light
            case .medium: return .medium
            case .heavy: return .heavy
            }
        }
    #endif
}

extension View {
    /// Adds haptic feedback on tap
    func gestureFeedback(_ type: GestureFeedbackModifier.FeedbackType = .light) -> some View {
        modifier(GestureFeedbackModifier(type: type))
    }
}

// MARK: - Content Visibility Modifier

/// Smoothly hides/shows content with animation
struct VisibilityModifier: ViewModifier {
    let isVisible: Bool
    let animation: Animation

    func body(content: Content) -> some View {
        content
            .frame(height: isVisible ? nil : 0)
            .clipped()
            .opacity(isVisible ? 1 : 0)
            .animation(animation, value: isVisible)
    }
}

extension View {
    /// Smoothly animates visibility with fade and size change
    func smoothVisibility(
        _ isVisible: Bool,
        animation: Animation = .easeInOut(duration: DesignTokens.Animation.normal)
    ) -> some View {
        modifier(VisibilityModifier(isVisible: isVisible, animation: animation))
    }
}

// MARK: - Padding Modifier

/// Applies consistent padding based on component type
struct PaddingModifier: ViewModifier {
    enum Style {
        case compact
        case standard
        case relaxed
        case modal
    }

    let style: Style

    func body(content: Content) -> some View {
        // Each branch calls SwiftUI's built-in `padding(_: CGFloat)` overload, NOT
        // the `padding(_ style: PaddingModifier.Style)` extension defined below.
        // Adding a `PaddingModifier.Style` call here would produce infinite recursion
        // identical to the BackgroundModifier crash fixed in commit <fix-hash>.
        switch style {
        case .compact:
            content.padding(DesignTokens.Spacing.compact)

        case .standard:
            content.padding(DesignTokens.Spacing.standard)

        case .relaxed:
            content.padding(DesignTokens.Spacing.relaxed)

        case .modal:
            content.padding(DesignTokens.Component.Modal.cornerRadius)
        }
    }
}

extension View {
    /// Applies consistent padding based on component type.
    ///
    /// - Important: Do NOT call `self.padding(_: PaddingModifier.Style)` inside
    ///   `PaddingModifier.body` — that resolves to this extension and causes
    ///   infinite recursion. Use SwiftUI's built-in `padding(_: CGFloat)` instead.
    func padding(_ style: PaddingModifier.Style) -> some View {
        modifier(PaddingModifier(style: style))
    }
}

// MARK: - Background Modifier

/// Applies themed background with optional corner radius
struct BackgroundModifier: ViewModifier {
    let color: Color
    let cornerRadius: CGFloat?

    func body(content: Content) -> some View {
        content
            // Use the view-builder overload to avoid resolving to the custom
            // `background(_ color: Color, cornerRadius:)` extension, which
            // would re-invoke BackgroundModifier and overflow the stack.
            .background { color }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? 0))
    }
}

extension View {
    /// Applies themed background.
    ///
    /// - Important: Do NOT call `self.background(_ color: Color, ...)` inside
    ///   `BackgroundModifier.body` — that resolves to this extension and causes
    ///   infinite recursion. Use `content.background { color }` (the `@ViewBuilder`
    ///   overload) to bind to SwiftUI's built-in instead.
    func background(_ color: Color, cornerRadius: CGFloat? = nil) -> some View {
        modifier(BackgroundModifier(color: color, cornerRadius: cornerRadius))
    }
}

// MARK: - Border Modifier

/// Applies themed border with consistent styling
struct BorderModifier: ViewModifier {
    let color: Color
    let width: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: width)
            )
    }
}

extension View {
    /// Applies themed border with consistent styling.
    ///
    /// - Important: Do NOT call `self.border(_:width:cornerRadius:)` inside
    ///   `BorderModifier.body` — that resolves to this extension and causes
    ///   infinite recursion. Use `.overlay(RoundedRectangle(...).stroke(...))` directly.
    func border(
        _ color: Color,
        width: CGFloat = 1,
        cornerRadius: CGFloat = DesignTokens.CornerRadius.small
    ) -> some View {
        modifier(BorderModifier(color: color, width: width, cornerRadius: cornerRadius))
    }
}

// MARK: - Card Style Modifier

/// Applies card styling with background, shadow, and padding
struct CardStyleModifier: ViewModifier {
    let backgroundColor: Color
    let shadowLevel: ElevationModifier.Level

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.medium))
            .elevation(shadowLevel)
    }
}

extension View {
    /// Applies card styling with background, shadow, and padding
    func cardStyle(
        backgroundColor: Color,
        shadowLevel: ElevationModifier.Level = .standard
    ) -> some View {
        modifier(CardStyleModifier(backgroundColor: backgroundColor, shadowLevel: shadowLevel))
    }
}

// MARK: - Button Style Modifier

/// Applies consistent button styling
struct ButtonStyleModifier: ViewModifier {
    let backgroundColor: Color
    let foregroundColor: Color
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, DesignTokens.Component.Button.paddingHorizontal)
            .padding(.vertical, DesignTokens.Component.Button.heightSmall)
            .background(isEnabled ? backgroundColor : backgroundColor.opacity(0.5))
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            .scaleEffect(isEnabled ? 1.0 : 0.98)
    }
}

extension View {
    /// Applies consistent button styling
    func buttonStyle(
        backgroundColor: Color,
        foregroundColor: Color,
        isEnabled: Bool = true
    ) -> some View {
        modifier(ButtonStyleModifier(
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            isEnabled: isEnabled
        ))
    }
}

// MARK: - Icon Button Style Modifier

/// Applies icon-only button styling with proper tap target
struct IconButtonStyleModifier: ViewModifier {
    let backgroundColor: Color
    let iconColor: Color
    let size: CGFloat
    let isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(isEnabled ? backgroundColor : backgroundColor.opacity(0.5))
            .foregroundColor(iconColor)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
            .interactive()
    }
}

extension View {
    /// Applies icon-only button styling with proper tap target
    func iconButtonStyle(
        backgroundColor: Color,
        iconColor: Color,
        size: CGFloat = DesignTokens.Component.Button.iconSize,
        isEnabled: Bool = true
    ) -> some View {
        modifier(IconButtonStyleModifier(
            backgroundColor: backgroundColor,
            iconColor: iconColor,
            size: size,
            isEnabled: isEnabled
        ))
    }
}

// MARK: - Text Style Modifier

/// Applies consistent text styling
struct TextStyleModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight))
            .foregroundColor(color)
    }
}

extension View {
    /// Applies consistent text styling
    func textStyle(
        size: CGFloat,
        color: Color,
        weight: Font.Weight = .regular
    ) -> some View {
        modifier(TextStyleModifier(size: size, weight: weight, color: color))
    }
}

// MARK: - Shimmer Effect Modifier

/// Applies shimmer loading effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.5), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 3)
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    /// Applies shimmer loading effect
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Tooltip Modifier

/// Shows tooltip on hover
struct TooltipModifier: ViewModifier {
    let text: String
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isHovered {
                    Text(text)
                        .font(.caption)
                        .padding(.horizontal, DesignTokens.Spacing.compact)
                        .padding(.vertical, DesignTokens.Spacing.tight)
                        .background(Color.secondary.opacity(0.9))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.15), value: isHovered)
                        .offset(y: -DesignTokens.Spacing.relaxed)
                }
            }
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    /// Shows tooltip on hover
    func tooltip(_ text: String) -> some View {
        modifier(TooltipModifier(text: text))
    }
}
