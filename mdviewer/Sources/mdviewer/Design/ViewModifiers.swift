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
