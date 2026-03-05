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
            insertion: .identity.animation(DesignTokens.AnimationPreset.standard),
            removal: .scale(scale: 0.98).combined(with: .opacity)
        )
    }

    /// Elegant slide transition from edge with fade
    static func elegantSlide(from edge: Edge) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: edge)
                .combined(with: .opacity)
                .animation(DesignTokens.AnimationPreset.standard),
            removal: .opacity
                .animation(DesignTokens.AnimationPreset.fast)
        )
    }

    /// Popup transition with scale and bounce
    static var popupScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8)
                .combined(with: .opacity)
                .animation(DesignTokens.AnimationPreset.spring(response: 0.28, damping: 0.75)),
            removal: .scale(scale: 0.9).combined(with: .opacity)
        )
    }

    /// Liquid morph transition for mode switching with matched geometry
    static var liquidMorph: AnyTransition {
        .asymmetric(
            insertion: .opacity
                .animation(DesignTokens.AnimationPreset.medium),
            removal: .opacity
                .animation(DesignTokens.AnimationPreset.fast)
        )
    }

    /// Spring slide with bounce for sidebar
    static func springSlide(from edge: Edge) -> AnyTransition {
        .asymmetric(
            insertion: .move(edge: edge)
                .combined(with: .opacity)
                .animation(DesignTokens.AnimationPreset.spring(response: 0.35, damping: 0.8)),
            removal: .move(edge: edge)
                .combined(with: .opacity)
                .animation(DesignTokens.AnimationPreset.fast)
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

    /// Applies adaptive animation based on system version using DesignTokens
    func adaptiveAnimation<Value: Equatable>(
        _ value: Value,
        duration: TimeInterval = DesignTokens.Animation.normal
    ) -> some View {
        animation(DesignTokens.AnimationPreset.forDuration(duration), value: value)
    }

    /// Applies a contextual spring animation for interactive elements
    func contextualSpring<Value: Equatable>(_ value: Value) -> some View {
        animation(DesignTokens.AnimationPreset.spring(response: 0.3, damping: 0.8), value: value)
    }

    /// Applies a snappy animation for quick interactions
    func snappyAnimation<Value: Equatable>(_ value: Value) -> some View {
        animation(DesignTokens.AnimationPreset.fast, value: value)
    }

    /// Applies a bouncy animation for playful interactions (macOS 15+)
    func bouncyAnimation<Value: Equatable>(_ value: Value) -> some View {
        if #available(macOS 15.0, iOS 17.0, *) {
            return AnyView(animation(.bouncy, value: value))
        } else {
            return AnyView(
                animation(DesignTokens.AnimationPreset.spring(response: 0.35, damping: 0.7), value: value)
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
                // Trigger any pending animations - implementer should add state changes here
            }
        }
    }

    /// Applies an animation with a specified delay using DispatchQueue
    func delayedAnimation<Value: Equatable>(
        _ value: Value,
        animation: Animation = DesignTokens.AnimationPreset.standard,
        delay: TimeInterval
    ) -> some View {
        onChange(of: value) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(animation) {
                    // State change handled by parent view
                }
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
        }
        return AnyView(self)
    }

    /// Applies different animations for appear and disappear
    func directionalAnimation<Value: Equatable>(
        _ value: Value,
        isAppearing: Bool
    ) -> some View {
        let anim: Animation = isAppearing
            ? DesignTokens.AnimationPreset.forDuration(DesignTokens.Animation.normal)
            : DesignTokens.AnimationPreset.fast
        return AnyView(animation(anim, value: value))
    }
}
