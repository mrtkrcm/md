//
//  ToolbarVisibilityController.swift
//  mdviewer
//
//  Manages toolbar auto-hide behavior based on scroll position.
//

internal import Foundation
internal import SwiftUI

/// Tracks scroll direction and position to control toolbar visibility.
/// NOT an ObservableObject — visibility progress is communicated exclusively
/// via the callback to avoid SwiftUI body re-evaluation on every scroll frame.
@MainActor
final class ToolbarVisibilityController {
    /// Current visibility state: true = visible, false = hidden.
    private(set) var isVisible: Bool = true

    /// Continuous visibility value retained for tests and callers that
    /// animate based on toolbar progress.
    private(set) var visibilityProgress: CGFloat = 1

    /// Called exactly once when visibility state flips.
    var onVisibilityChange: ((Bool) -> Void)?

    /// Called when visibility progress changes by a meaningful amount.
    var onVisibilityProgressChange: ((CGFloat) -> Void)?

    let hideThreshold: CGFloat = 30
    private let microUpdateThreshold: CGFloat = 0.01

    private var lastScrollOffset: CGFloat = 0
    private var suspendScrollHandlingUntil: Date = .distantPast

    init() {}

    /// Handles live scroll samples during an active gesture.
    func updateLiveScroll(currentOffset: CGFloat, canScroll: Bool) {
        guard canScroll else {
            setVisibilityProgress(1)
            setVisibility(true)
            return
        }

        let now = Date()
        if now < suspendScrollHandlingUntil {
            return
        }

        lastScrollOffset = currentOffset
        setVisibilityProgress(progress(for: currentOffset))

        // Simple threshold check: show if above threshold, hide if below
        let shouldBeVisible = currentOffset <= hideThreshold
        setVisibility(shouldBeVisible)
    }

    /// Offset-based API retained for non-gesture callers.
    func updateScroll(offset: CGFloat, contentHeight: CGFloat, visibleHeight: CGFloat) {
        let canScroll = contentHeight > visibleHeight + 1
        updateLiveScroll(currentOffset: offset, canScroll: canScroll)
    }

    /// Explicitly show toolbar (e.g., when mouse enters toolbar area).
    func show() {
        setVisibilityProgress(1)
        setVisibility(true)
    }

    /// Reset state (e.g., when changing documents).
    func reset() {
        suspendScrollHandlingUntil = .distantPast
        lastScrollOffset = 0
        setVisibilityProgress(1)
        setVisibility(true)
    }

    /// Temporarily ignores scroll updates to ride out layout compensation events.
    func suspendUpdates(for duration: TimeInterval) {
        let resumeAt = Date().addingTimeInterval(max(duration, 0))
        if resumeAt > suspendScrollHandlingUntil {
            suspendScrollHandlingUntil = resumeAt
        }
    }

    private func setVisibility(_ visible: Bool) {
        guard isVisible != visible else { return }
        isVisible = visible
        onVisibilityChange?(visible)
    }

    private func setVisibilityProgress(_ progress: CGFloat) {
        let clampedProgress = min(max(progress, 0), 1)
        guard abs(visibilityProgress - clampedProgress) >= microUpdateThreshold else { return }
        visibilityProgress = clampedProgress
        onVisibilityProgressChange?(clampedProgress)
    }

    private func progress(for offset: CGFloat) -> CGFloat {
        let collapseRange = hideThreshold * 2
        let collapseEnd = hideThreshold + collapseRange

        if offset <= hideThreshold {
            return 1
        }
        if offset >= collapseEnd {
            return 0
        }

        return (collapseEnd - offset) / collapseRange
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
