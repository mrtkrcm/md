//
//  ToolbarVisibilityController.swift
//  mdviewer
//
//  Manages toolbar auto-hide behavior based on scroll position.
//

internal import Foundation
internal import SwiftUI

/// Tracks scroll direction and position to control toolbar visibility.
@MainActor
final class ToolbarVisibilityController: ObservableObject {
    /// Current visibility state of the toolbar.
    @Published private(set) var isVisible: Bool = true

    /// Scroll offset after which toolbar may hide (in points).
    let hideThreshold: CGFloat
    let showThreshold: CGFloat

    /// Ignore tiny scroll deltas from trackpad noise and bounce.
    private let directionNoiseThreshold: CGFloat = 1.0

    /// Called synchronously when visibility changes — bypasses the SwiftUI render cycle.
    var onVisibilityChange: ((Bool) -> Void)?

    private let debounceInterval: TimeInterval
    private var suspendScrollHandlingUntil: Date = .distantPast
    private var gestureStartOffset: CGFloat?
    private var lastHideTimestamp: Date?
    private var compatibilityLastOffset: CGFloat?
    private var compatibilityAccumulatedScrollUp: CGFloat = 0

    init(
        hideThreshold: CGFloat = 20,
        showThreshold: CGFloat = 1,
        debounceInterval: TimeInterval = 0.05,
        scrollThrottleInterval _: TimeInterval = 0.0
    ) {
        self.hideThreshold = hideThreshold
        self.showThreshold = showThreshold
        self.debounceInterval = debounceInterval
    }

    /// Captures the starting offset for a live scroll gesture.
    func beginScrollGesture(startOffset: CGFloat) {
        gestureStartOffset = startOffset
    }

    /// Handles live scroll samples during an active gesture.
    /// Uses instantaneous direction from per-sample delta to make toolbar transitions feel immediate.
    func updateLiveScroll(delta: CGFloat, currentOffset: CGFloat, canScroll: Bool) {
        guard canScroll else {
            gestureStartOffset = nil
            if !isVisible {
                setVisible(true)
            }
            return
        }

        let now = Date()
        if now < suspendScrollHandlingUntil {
            return
        }

        guard abs(delta) >= directionNoiseThreshold else { return }

        if delta > 0 {
            if currentOffset > hideThreshold, isVisible {
                setVisible(false)
                lastHideTimestamp = now
            }
        } else if delta < 0 {
            if !isVisible, abs(delta) >= showThreshold {
                setVisible(true)
            }
        }
    }

    /// Legacy offset-based API retained for tests and non-gesture callers.
    /// Converts absolute offsets to directional deltas and applies hysteresis/debouncing.
    func updateScroll(offset: CGFloat, contentHeight: CGFloat, visibleHeight: CGFloat) {
        let canScroll = contentHeight > visibleHeight + 1
        guard canScroll else {
            compatibilityLastOffset = offset
            compatibilityAccumulatedScrollUp = 0
            if !isVisible {
                setVisible(true)
            }
            return
        }

        let now = Date()
        if now < suspendScrollHandlingUntil {
            compatibilityLastOffset = offset
            return
        }

        let previousOffset = compatibilityLastOffset ?? 0
        compatibilityLastOffset = offset
        let delta = offset - previousOffset
        guard abs(delta) >= directionNoiseThreshold else { return }

        if delta > 0 {
            compatibilityAccumulatedScrollUp = 0
            if offset > hideThreshold, isVisible {
                setVisible(false)
                lastHideTimestamp = now
            }
            return
        }

        compatibilityAccumulatedScrollUp += -delta
        guard !isVisible, compatibilityAccumulatedScrollUp >= showThreshold else { return }
        let isDebounced = now.timeIntervalSince(lastHideTimestamp ?? .distantPast) >= debounceInterval
        guard isDebounced else { return }
        setVisible(true)
        compatibilityAccumulatedScrollUp = 0
    }

    /// Call this when a live scroll gesture ends.
    /// Uses gesture delta and current visibility to decide transitions.
    /// - Parameters:
    ///   - delta: End offset minus start offset for the gesture.
    ///   - finalOffset: Final scroll offset after gesture ends.
    func updateScrollGesture(delta: CGFloat, finalOffset: CGFloat, canScroll: Bool) {
        guard canScroll else {
            gestureStartOffset = nil
            if !isVisible {
                setVisible(true)
            }
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
    /// Includes a small delay to prevent flickering when mouse moves across boundaries.
    func show() {
        if !isVisible {
            setVisible(true)
        }
    }

    /// Reset state (e.g., when changing documents).
    func reset() {
        suspendScrollHandlingUntil = .distantPast
        gestureStartOffset = nil
        lastHideTimestamp = nil
        compatibilityLastOffset = nil
        compatibilityAccumulatedScrollUp = 0
        setVisible(true)
    }

    /// Temporarily ignores scroll updates to ride out layout compensation events.
    func suspendUpdates(for duration: TimeInterval) {
        let resumeAt = Date().addingTimeInterval(max(duration, 0))
        if resumeAt > suspendScrollHandlingUntil {
            suspendScrollHandlingUntil = resumeAt
        }
    }

    private func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
        onVisibilityChange?(visible)
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
