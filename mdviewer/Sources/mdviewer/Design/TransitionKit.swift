//
//  TransitionKit.swift
//  mdviewer
//
//  Modern transition and animation utilities for liquid design system.
//

internal import SwiftUI

// MARK: - Modern Transitions

extension AnyTransition {
    /// Smooth expansion transition with staggered opacity
    static var smoothExpand: AnyTransition {
        .asymmetric(
            insertion: .identity.animation(.easeOut(duration: 0.22)),
            removal: .scale(scale: 0.98).combined(with: .opacity)
        )
    }

    /// Elegant slide transition from edge with fade
    static func elegantSlide(from edge: Edge) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: edge)
                .combined(with: .opacity)
                .animation(.easeOut(duration: 0.22)),
            removal: .opacity
                .animation(.easeIn(duration: 0.15))
        )
    }

    /// Popup transition with scale and bounce
    static var popupScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8)
                .combined(with: .opacity)
                .animation(.spring(response: 0.28, dampingFraction: 0.75, blendDuration: 0)),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        )
    }
}

// MARK: - Animation Modifiers

extension View {
    /// Applies a gentle fade transition for content changes
    func fadeContent() -> some View {
        transition(.opacity)
    }

    /// Applies a smooth scale transition for appearance/disappearance
    func scaleContent() -> some View {
        transition(.scale.combined(with: .opacity))
    }

    /// Applies adaptive animation based on system version
    func adaptiveAnimation<Value: Equatable>(
        _ value: Value,
        duration: TimeInterval = DesignTokens.Animation.normal
    ) -> some View {
        if #available(macOS 15.0, iOS 17.0, *) {
            return AnyView(animation(.smooth(duration: duration), value: value))
        } else {
            return AnyView(animation(.easeInOut(duration: duration), value: value))
        }
    }

    /// Applies a contextual spring animation for interactive elements
    func contextualSpring<Value: Equatable>(_ value: Value) -> some View {
        if #available(macOS 15.0, iOS 17.0, *) {
            return AnyView(animation(.bouncy, value: value))
        } else {
            return AnyView(
                animation(.spring(response: 0.3, dampingFraction: 0.8), value: value)
            )
        }
    }
}

// MARK: - Delay Utilities

extension View {
    /// Delays the execution of a view update (useful for sequenced animations)
    @MainActor
    func animationDelay(_ delay: TimeInterval) -> some View {
        onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                // Trigger any pending animations
            }
        }
    }
}

// MARK: - Conditional Animations

extension View {
    /// Applies animation only when condition is true
    func animationWhen<Value: Equatable>(
        _ condition: Bool,
        _ anim: Animation,
        value: Value
    ) -> some View {
        if condition {
            return AnyView(animation(anim, value: value))
        } else {
            return AnyView(self)
        }
    }

    /// Applies different animations for appear and disappear
    func directionalAnimation<Value: Equatable>(
        _ value: Value,
        isAppearing: Bool
    ) -> some View {
        let anim: Animation = isAppearing
            ? .easeOut(duration: DesignTokens.Animation.normal)
            : .easeIn(duration: DesignTokens.Animation.fast)
        return AnyView(animation(anim, value: value))
    }
}
