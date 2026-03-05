//
//  ToolbarVisibilityController.swift
//  mdviewer
//
//  Manages toolbar auto-hide behavior based on scroll position.
//

internal import Foundation
internal import SwiftUI

/// Tracks scroll direction and position to control toolbar visibility.
/// Provides stable, smooth animations optimized for 120fps displays.
@MainActor
final class ToolbarVisibilityController: ObservableObject {
    /// Current visibility progress (0.0 = fully hidden, 1.0 = fully visible).
    @Published private(set) var visibilityProgress: CGFloat = 1.0

    /// Scroll offset after which toolbar begins hiding (in points).
    let hideThreshold: CGFloat = 30

    /// Distance over which toolbar gradually shrinks (in points).
    let shrinkRange: CGFloat = 60

    /// Ignore tiny scroll deltas from trackpad noise and bounce.
    private let directionNoiseThreshold: CGFloat = 1.0

    /// Called when visibility progress changes for smooth animations.
    var onVisibilityProgressChange: ((CGFloat) -> Void)?

    // Hysteresis: toolbar auto-shows only when within this distance of the top.
    private let atTopThreshold: CGFloat = 8

    private var lastScrollOffset: CGFloat = 0
    private var suspendScrollHandlingUntil: Date = .distantPast
    private var gestureStartOffset: CGFloat?
    private var lastHideTimestamp: Date?

    init() {}

    /// Captures the starting offset for a live scroll gesture.
    func beginScrollGesture(startOffset: CGFloat) {
        gestureStartOffset = startOffset
    }

    /// Handles live scroll samples during an active gesture.
    /// Updates visibility progress based on scroll position for stable 120fps animations.
    func updateLiveScroll(delta: CGFloat, currentOffset: CGFloat, canScroll: Bool) {
        guard canScroll else {
            gestureStartOffset = nil
            setVisibilityProgress(1.0)
            return
        }

        let now = Date()
        if now < suspendScrollHandlingUntil {
            return
        }

        lastScrollOffset = currentOffset

        // Show at top immediately (tight zone for hysteresis)
        if currentOffset <= atTopThreshold {
            setVisibilityProgress(1.0)
            return
        }

        // Calculate progressive shrinking based on scroll position
        let shrinkStart = hideThreshold
        let shrinkEnd = hideThreshold + shrinkRange

        if currentOffset <= shrinkStart {
            // Fully visible before shrink threshold
            setVisibilityProgress(1.0)
        } else if currentOffset >= shrinkEnd {
            // Fully hidden after shrink range
            setVisibilityProgress(0.0)
        } else {
            // Gradually shrink within the shrink range
            let progress = 1.0 - ((currentOffset - shrinkStart) / shrinkRange)
            setVisibilityProgress(max(0.0, min(1.0, progress)))
        }
    }

    /// Offset-based API retained for non-gesture callers.
    func updateScroll(offset: CGFloat, contentHeight: CGFloat, visibleHeight: CGFloat) {
        let canScroll = contentHeight > visibleHeight + 1
        updateLiveScroll(delta: offset - lastScrollOffset, currentOffset: offset, canScroll: canScroll)
    }

    /// Call this when a live scroll gesture ends.
    func updateScrollGesture(delta: CGFloat, finalOffset: CGFloat, canScroll: Bool) {
        guard canScroll else {
            gestureStartOffset = nil
            setVisibilityProgress(1.0)
            return
        }

        let now = Date()
        if now < suspendScrollHandlingUntil {
            return
        }

        let resolvedDelta: CGFloat
        if let gestureStartOffset {
            resolvedDelta = finalOffset - gestureStartOffset
            self.gestureStartOffset = nil
        } else {
            resolvedDelta = delta
        }

        updateLiveScroll(delta: resolvedDelta, currentOffset: finalOffset, canScroll: canScroll)
    }

    /// Explicitly show toolbar (e.g., when mouse enters toolbar area).
    func show() {
        setVisibilityProgress(1.0)
    }

    /// Reset state (e.g., when changing documents).
    func reset() {
        suspendScrollHandlingUntil = .distantPast
        gestureStartOffset = nil
        lastHideTimestamp = nil
        lastScrollOffset = 0
        setVisibilityProgress(1.0)
    }

    /// Temporarily ignores scroll updates to ride out layout compensation events.
    func suspendUpdates(for duration: TimeInterval) {
        let resumeAt = Date().addingTimeInterval(max(duration, 0))
        if resumeAt > suspendScrollHandlingUntil {
            suspendScrollHandlingUntil = resumeAt
        }
    }

    private func setVisibilityProgress(_ progress: CGFloat) {
        guard abs(visibilityProgress - progress) > 0.01 else { return } // Prevent micro-updates
        visibilityProgress = progress
        onVisibilityProgressChange?(progress)
    }
}

// MARK: - Environment Key

private struct ToolbarVisibilityControllerKey: EnvironmentKey {
    static let defaultValue: ToolbarVisibilityController? = nil
}

extension EnvironmentValues {
    var toolbarVisibilityController: ToolbarVisibilityController? {
        get { self[ToolbarVisibilityControllerKey.self] }
        set { self[ToolbarVisibilityControllerKey.self] = newValue }
    }
}
