//
//  AccessibilityConfiguration.swift
//  mdviewer
//

internal import SwiftUI

// MARK: - Accessibility Configuration

/// Centralized accessibility settings that respond to system preferences.
/// All views should reference these values instead of hardcoding accessibility behavior.
@MainActor
enum AccessibilityConfiguration {
    /// Animation duration multiplier based on reduce motion preference
    static func animationMultiplier(reduceMotion: Bool) -> Double {
        reduceMotion ? 0.0 : 1.0
    }

    /// Returns appropriate transition based on motion preferences
    static func adaptiveTransition(
        from edge: Edge,
        reduceMotion: Bool
    ) -> AnyTransition {
        if reduceMotion {
            return .opacity
        }
        return .springSlide(from: edge)
    }

    /// Returns appropriate spring animation or instant transition
    static func adaptiveSpring(
        reduceMotion: Bool,
        response: TimeInterval = 0.28,
        damping: CGFloat = 0.82
    ) -> Animation {
        if reduceMotion {
            return .linear(duration: 0.01)
        }
        return .spring(response: response, dampingFraction: damping)
    }

    /// Returns appropriate easing animation
    static func adaptiveEaseInOut(
        duration: TimeInterval,
        reduceMotion: Bool
    ) -> Animation {
        if reduceMotion {
            return .linear(duration: 0.01)
        }
        return .easeInOut(duration: duration)
    }
}

// MARK: - View Modifiers

extension View {
    /// Applies an animation that respects the user's reduce motion preference
    func accessibleAnimation<V: Equatable>(
        _ animation: Animation,
        value: V,
        reduceMotion: Bool
    ) -> some View {
        if reduceMotion {
            return self.animation(.linear(duration: 0.01), value: value)
        }
        return self.animation(animation, value: value)
    }

    /// Applies a transition that respects reduce motion preference
    func accessibleTransition(
        from edge: Edge,
        reduceMotion: Bool
    ) -> some View {
        transition(AccessibilityConfiguration.adaptiveTransition(from: edge, reduceMotion: reduceMotion))
    }
}
